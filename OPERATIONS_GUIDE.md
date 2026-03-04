# Operations Guide: Books App DevOps Project
**Combined Runbook, Workbook & Troubleshooting Manual**

---

## 1. RUNBOOK (How to Operate)
*Daily operations and maintenance tasks.*

### 1.1 Accessing the Application
- **Web UI:** `http://<SERVER_IP>` (Port 80)
- **Backend API:** `http://<SERVER_IP>:5000/api/books`
- **Database:** Accessible only from within the EC2 instance via Docker.

### 1.2 ChatOps: Updating the Header via Telegram
1. Open your Telegram Bot.
2. Send the command (or press the button) to change the header.
3. Enter the new text (e.g., "Welcome to Vitalii's Book Store").
4. **Wait 1-2 minutes** for the GitHub Action to complete.
5. Refresh the browser to see the changes.

### 1.3 Manual Deployment / Restart
If you need to restart the app manually on the server:
```bash
ssh ubuntu@<SERVER_IP>
cd /home/ubuntu
docker-compose down
docker-compose pull
docker-compose up -d
2. WORKBOOK (How it was Built)
Technical history and implementation steps.

2.1 Infrastructure & Security
Cloud: AWS EC2 (Ubuntu 22.04).
Security Groups: Ports 22 (SSH), 80 (HTTP), 5000 (API) opened.
SSH Setup: Generated RSA 4096-bit keys for secure GitHub-to-EC2 communication.
2.2 CI/CD Pipeline Logic
Step 1 (Terraform): Provisioning (Optional/Manual).
Step 2 (Docker): Build & Push images to Docker Hub (oskalibriya/books-*).
Step 3 (Ansible):
Triggered by Step 2 or Telegram Bot.
Updates index.html via sed.
Commits changes to Git.
Runs Ansible Playbook to sync files and restart containers.
3. TROUBLESHOOTING (How to Fix)
Common issues and their verified solutions.

Issue	Symptom	Solution
Git Push 403	Permission denied in GitHub Actions	Enable "Read and write permissions" in Repo Settings > Actions.
Header Not Changing	Success in logs, but old text on site	Ensure volumes are mapped in docker-compose.yml and Ansible copies the file.
Git Conflict	! [rejected] main -> main	Run git pull --rebase origin main before pushing locally.
SSH Timeout	Action hangs on Ansible step	Verify SERVER_IP secret and ensure ssh-keyscan is in the workflow.
4. AI ASSISTANCE (DeepAgent Integration)
This project was co-engineered with DeepAgent (Abacus.AI).

Strategic Contributions:

Architecture: Designed the ChatOps loop (Telegram -> GitHub -> EC2).
Optimization: Implemented the Volume Mount strategy for instant updates.
Problem Solving: Resolved complex Git permission and synchronization issues