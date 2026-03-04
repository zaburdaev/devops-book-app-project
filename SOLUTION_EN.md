Project Overview
Architecture
Technologies Used
CI/CD Pipeline Design
ChatOps Integration (Telegram Bot)
Deployment Flow (Step-by-Step)
Error Handling and Troubleshooting (What went wrong and how we fixed it)
Lessons Learned and Possible Improvements



# Books App DevOps Project – Solution Documentation

## 1. Project Overview

This project implements a complete DevOps pipeline for a three‑tier web application called **Books App**. The goal is to demonstrate an end‑to‑end CI/CD and ChatOps workflow using industry‑standard tools:

- Application code is stored in GitHub.
- Infrastructure runs on an AWS EC2 instance.
- Configuration and deployment are automated using **Ansible**, **Docker**, and **GitHub Actions** (Terraform can be added as a next step).
- A **Telegram ChatOps bot** can trigger deployments and change the header text of the frontend page via a simple chat command.

Final result:

- A running Books App (frontend + backend + database) on EC2.
- A CI/CD pipeline that:
  - Builds and pushes Docker images (Step 2, not fully described here).
  - Deploys and updates the application using Ansible and Docker Compose (Step 3).
- A Telegram bot that:
  - Accepts a new header text from the user.
  - Creates a commit in GitHub with the updated header.
  - Triggers a GitHub Actions workflow that redeploys the app.
  - Sends success/failure notifications back in Telegram.

---

## 2. Architecture

### 2.1 Application Architecture

The Books App is a classic three‑tier application:

1. **Database (db)**  
   - Docker image: `postgres:16-alpine`  
   - Environment:
     - `POSTGRES_DB=booksdb`
     - `POSTGRES_USER=booksuser`
     - `POSTGRES_PASSWORD=bookspass`
   - Initialization scripts:
     - `db/schema.sql` – schema creation
     - `db/seed.sql` – seed data
   - Exposed port: `5432`
   - Health check using `pg_isready`

2. **Backend (`books-backend`)**  
   - Docker image: `oskalibriya/books-backend:latest`
   - Environment variables:
     - `DB_HOST=db`
     - `DB_PORT=5432`
     - `DB_NAME=booksdb`
     - `DB_USER=booksuser`
     - `DB_PASSWORD=bookspass`
   - Exposed port: `5000`
   - Depends on healthy `db` service

3. **Frontend (`books-frontend`)**  
   - Docker image: `oskalibriya/books-frontend:latest`
   - Exposed port: `80`
   - Serves a static HTML page (`index.html`) with a header `<h1>…</h1>` that we update dynamically via ChatOps.
   - The file `frontend/index.html` is mounted into the container via a Docker volume so that we can change it without rebuilding the image.

**Docker Compose configuration (`books-app/docker-compose.yml`):**

```yaml
services:
  db:
    image: postgres:16-alpine
    container_name: booksdb
    environment:
      POSTGRES_DB: booksdb
      POSTGRES_USER: booksuser
      POSTGRES_PASSWORD: bookspass
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./db/schema.sql:/docker-entrypoint-initdb.d/01_schema.sql
      - ./db/seed.sql:/docker-entrypoint-initdb.d/02_seed.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U booksuser -d booksdb"]
      interval: 5s
      timeout: 5s
      retries: 10

  backend:
    image: oskalibriya/books-backend:latest
    container_name: books-backend
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: booksdb
      DB_USER: booksuser
      DB_PASSWORD: bookspass
    ports:
      - "5000:5000"
    depends_on:
      db:
        condition: service_healthy

  frontend:
    image: oskalibriya/books-frontend:latest
    container_name: books-frontend
    ports:
      - "80:80"
    volumes:
      - ./frontend/index.html:/usr/share/nginx/html/index.html
    depends_on:
      - backend

volumes:
  db_data:
The key for ChatOps is:

yaml
Copy
    volumes:
      - ./frontend/index.html:/usr/share/nginx/html/index.html
This ensures the container always uses the current index.html from the filesystem.

2.2 Infrastructure Architecture
Cloud: AWS
Compute: EC2 (Ubuntu)
Config management & deployment: Ansible
Container runtime: Docker + Docker Compose
Source control: GitHub (devops-book-app-project)
High‑level flow:

Ansible connects via SSH to the EC2 instance.
Installs Docker and Docker Compose.
Copies application and configuration files.
Runs Docker Compose to start/update the stack.
(Terraform can be used to create the EC2 instance and networking, but this is outside the minimal scope of this document.)

3. Technologies Used
Git, GitHub – version control and code hosting
GitHub Actions – CI/CD pipelines
Docker, Docker Compose – containerization and orchestration
Ansible – configuration management and deployment
AWS EC2 – runtime environment
PostgreSQL 16 – database
Python / Flask – backend (inside Docker)
Nginx + static HTML – frontend
Telegram Bot API – ChatOps interface
4. CI/CD Pipeline Design
The project uses several GitHub Actions workflows. Here we focus on Step 3 – Ansible Deploy, which is also used by the Telegram ChatOps bot.

4.1 Workflow: Step 3 – Ansible Deploy
File: .github/workflows/deploy.yml

yaml
Copy
name: Step 3 - Ansible Deploy

on:
  workflow_run:
    workflows: ["Step 2 - Docker Build and Push"]
    types: [completed]
  workflow_dispatch:
    inputs:
      header_text:
        description: "New header text"
        required: false
        type: string
      triggered_by:
        description: "Who triggered this workflow"
        required: false
        default: "manual"
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    if: ${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          persist-credentials: true

      - name: Update header if triggered via ChatOps
        if: github.event_name == 'workflow_dispatch' && github.event.inputs.header_text != ''
        run: |
          sed -i "s|<h1>.*</h1>|<h1>${{ github.event.inputs.header_text }}</h1>|g" books-app/frontend/index.html
          git config user.name "ChatOps Bot"
          git config user.email "bot@devops.com"
          git add books-app/frontend/index.html
          git commit -m "Update header: ${{ github.event.inputs.header_text }}" || echo "No changes to commit"
          git push

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts

      - name: Run Ansible Playbook
        run: |
          ansible-playbook -i "${{ secrets.SERVER_IP }}," -u ${{ secrets.SERVER_USER }} --private-key ~/.ssh/id_rsa deploy.yml

      - name: Send Telegram notification on Success
        if: success()
        run: |
          curl -s -X POST "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
            -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
            -d text="✅ *Deploy Succeeded!* %0A🚀 Project: Books App %0A🔗 URL: http://${{ secrets.SERVER_IP }} %0A👤 User: ${{ github.actor }}" \
            -d parse_mode="Markdown"

      - name: Send Telegram notification on Failure
        if: failure()
        run: |
          curl -s -X POST "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
            -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
            -d text="❌ *Deploy Failed!* %0A⚠️ Check GitHub Actions logs: https://github.com/${{ github.repository }}/actions" \
            -d parse_mode="Markdown"
Key points:

The workflow can be triggered:
Automatically after Step 2 – Docker Build and Push completes.
Manually / via API (workflow_dispatch), which is what the Telegram bot uses.
header_text is used to modify <h1>…</h1> in index.html via sed.
The change is committed and pushed back to GitHub by github-actions[bot].
Ansible is then used to deploy the updated app to the EC2 instance.
Telegram notifications are sent on success or failure.
5. Ansible Deployment
File: deploy.yml (Ansible playbook in the repo root):

yaml
Copy
- name: Deploy Books App to EC2
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt: update_cache=yes

    - name: Install Docker
      apt:
        name: ["docker.io", "docker-compose"]
        state: present

    - name: Ensure Docker is running
      service:
        name: docker
        state: started
        enabled: yes

    - name: Copy DB scripts to server
      copy:
        src: ./books-app/db/
        dest: /home/ubuntu/db/

    - name: Copy frontend files to server
      copy:
        src: ./books-app/frontend/
        dest: /home/ubuntu/frontend/

    - name: Copy docker-compose.yml to server
      copy:
        src: ./books-app/docker-compose.yml
        dest: /home/ubuntu/docker-compose.yml

    - name: Pull latest images and run
      shell: |
        docker-compose down || true
        docker-compose pull
        docker-compose up -d
      args:
        chdir: /home/ubuntu
What it does:

Updates package cache.
Installs Docker and Docker Compose.
Ensures Docker is running and enabled at boot.
Copies:
DB scripts to /home/ubuntu/db/
Frontend files to /home/ubuntu/frontend/
docker-compose.yml to /home/ubuntu/docker-compose.yml
Runs docker-compose to redeploy the stack.
Thanks to the volume mapping in docker-compose.yml, the frontend container reads the updated index.html from /home/ubuntu/frontend/index.html.

6. ChatOps Integration (Telegram Bot)
High‑level flow:

The user presses a button in Telegram (e.g. "Change Header") and enters a new header text.
The Telegram bot:
Calls the GitHub Actions workflow_dispatch API for Step 3 - Ansible Deploy, passing:
header_text – the text provided by the user.
triggered_by – marker that this was triggered by the bot.
GitHub Actions:
Updates books-app/frontend/index.html using sed.
Commits and pushes the change.
Runs the Ansible playbook.
After completion, GitHub Actions sends a message back to Telegram using the Bot API and TELEGRAM_BOT_TOKEN.
This creates a closed ChatOps loop:
Telegram → GitHub → EC2 → Telegram.

7. Step‑by‑Step Process (Commands and Rationale)
7.1 Local Repository Setup
bash
Copy
# Clone the repository
git clone https://github.com/zaburdaev/devops-book-app-project.git
cd devops-book-app-project
Copied the books-app folder from the original training repo.
Verified structure: backend/, frontend/, db/, docker-compose.yml.
7.2 Configure Docker Compose
Main tasks:

Define services: db, backend, frontend.
Add volumes:
DB initialization: schema.sql, seed.sql.
Frontend index.html for dynamic header updates.
7.3 Create Ansible Playbook
File deploy.yml:

Install Docker & Docker Compose.
Copy DB scripts, frontend files, and docker-compose.yml.
Run Docker Compose:
yaml
Copy
docker-compose down || true
docker-compose pull
docker-compose up -d
7.4 Create GitHub Actions Workflow (Step 3)
File .github/workflows/deploy.yml:

Add triggers (workflow_run, workflow_dispatch).
Implement header update step via sed.
Commit and push changes from within the workflow:
Requires contents: write permissions.
Configure SSH with secrets:
SSH_PRIVATE_KEY
SERVER_IP
SERVER_USER
Run the Ansible playbook.
Send Telegram notifications using:
TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID
7.5 Fix GitHub Actions git push Permission Issue
Initial error:

text
Copy
Permission to ... denied to github-actions[bot].
fatal: unable to access 'https://github.com/...': The requested URL returned error: 403
Fix:

Repository Settings → Actions → General → Workflow permissions:
Enable Read and write permissions.
In workflow job:
yaml
Copy
permissions:
  contents: write
In actions/checkout:
yaml
Copy
with:
  persist-credentials: true
Now github-actions[bot] can successfully push commits.

7.6 Resolve Local vs Bot Commit Conflicts
When the bot commits to main, local git push can fail:

text
Copy
! [rejected] main -> main (fetch first)
Updates were rejected because the remote contains work that you do not have locally.
Solution:

bash
Copy
git pull --rebase origin main
git push origin main
This integrates bot commits into the local branch before pushing.

8. Errors and Troubleshooting
8.1 Header Not Updating on Website
Symptom:

Telegram: ✅ Deploy Succeeded.
GitHub Actions: green.
Website: header unchanged.
Root cause:

index.html was updated only in GitHub.
The frontend container used index.html baked into the Docker image.
No volume mount for index.html → container did not see new changes.
Fix:

Add volume mount in frontend service:
yaml
Copy
frontend:
  ...
  volumes:
    - ./frontend/index.html:/usr/share/nginx/html/index.html
Ensure Ansible copies frontend files:
yaml
Copy
- name: Copy frontend files to server
  copy:
    src: ./books-app/frontend/
    dest: /home/ubuntu/frontend/
Now the header updates immediately after each deployment.

8.2 GitHub Actions 403 on git push
Error:

text
Copy
remote: Permission to ... denied to github-actions[bot].
Cause:

Default GITHUB_TOKEN permissions were read‑only.
Fix:

Enable read/write permissions in repo settings.
Add permissions: contents: write and persist-credentials: true.
8.3 Local non-fast-forward Push Errors
Error:

text
Copy
! [rejected] main -> main (fetch first)
Cause:

Remote main contains additional commits from the bot.
Fix:

Sync with remote before push:
bash
Copy
git pull --rebase origin main
git push origin main
9. Lessons Learned and Potential Improvements
What was achieved:

A realistic CI/CD pipeline:
Docker images for backend and frontend.
Automated deployment to EC2 via Ansible and Docker Compose.
GitOps pattern:
Every state change (including header changes) flows through Git.
ChatOps:
Telegram bot as a convenient interface to manage deployment and content.
Possible improvements:

Add full Terraform configuration to automatically provision EC2 and networking.
Store sensitive data (DB passwords, tokens) in a secrets manager rather than env vars.
Add automated post‑deployment checks (curl tests, health endpoints).
Extend the Telegram bot:
Show current header.
Show container status (via docker ps).
Display latest deployment logs.
10. AI Assistance & DeepAgent Integration
This project was developed with the strategic assistance of DeepAgent (Abacus.AI), which acted as a virtual Senior DevOps Engineer.

How AI was used
Architecture Design
DeepAgent helped design the overall flow:
Telegram → GitHub → EC2 → Telegram.
Proposed using Docker Volumes to avoid rebuilding frontend images for each content change.
Debugging & Troubleshooting
Identified the reason for 403 errors during git push in GitHub Actions (insufficient permissions).
Provided exact YAML configuration changes for permissions and actions/checkout.
Helped analyze why the header was not updating even after a "successful" deployment and traced the issue to the difference between files inside the image and files on the host.
Code Generation
Assisted in writing the Ansible playbook (deploy.yml).
Helped structure the GitHub Actions workflow (deploy.yml in .github/workflows) following best practices.
Git Workflow & Conflict Resolution
Recommended using git pull --rebase origin main before pushing, to properly merge bot commits and maintain a clean history.
Key Problem Solved by AI
The most important technical problem was the "static header" issue:

Initially, the header text did not change on the website even though:
The bot updated index.html in GitHub.
GitHub Actions ran successfully.
Ansible completed without errors.
DeepAgent analyzed the situation and explained that:

The frontend container was using index.html baked into the Docker image.
The file updated in GitHub was never mounted into the running container.
AI‑driven solution:

Introduce a Docker volume to mount frontend/index.html into the Nginx document root.
Ensure that Ansible copies the updated frontend files to the EC2 instance before running docker-compose up.
This combination preserved containerization while enabling fully dynamic content updates driven by ChatOps commands.