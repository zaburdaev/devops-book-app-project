Project Overview
Architecture
Technologies Used
CI/CD Pipeline Design
ChatOps Integration (Telegram Bot)
Deployment Flow (Step-by-Step)
Error Handling and Troubleshooting (What went wrong and how we fixed it)
Lessons Learned and Possible Improvements








### `SOLUTION_RU.md`

```markdown
# Books App DevOps – Документация по решению

## 1. Обзор проекта

В этом проекте реализован полный DevOps‑pipeline для учебного веб‑приложения **Books App**. Цель — показать end‑to‑end процесс CI/CD и ChatOps с использованием современных инструментов:

- Код приложения хранится в GitHub.
- Приложение развёрнуто на виртуальной машине **AWS EC2**.
- Конфигурация и деплой автоматизированы с помощью **Ansible**, **Docker**, **Docker Compose** и **GitHub Actions** (Terraform можно добавить как следующий шаг).
- **Telegram‑бот (ChatOps)** позволяет менять заголовок на главной странице и запускать деплой одной командой из чата.

Итоговое решение:

- Рабочее приложение Books App (frontend + backend + БД) на EC2.
- CI/CD‑pipeline, который:
  - Собирает и пушит Docker‑образы (Step 2, здесь кратко).
  - Деплоит и обновляет приложение через Ansible и Docker Compose (Step 3).
- Telegram‑бот, который:
  - Принимает новый текст заголовка от пользователя.
  - Создаёт коммит в GitHub с обновлённым `index.html`.
  - Запускает GitHub Actions workflow.
  - Отправляет уведомления об успехе или ошибке обратно в Telegram.

---

## 2. Архитектура

### 2.1 Архитектура приложения

Books App — трёхзвенное приложение:

1. **База данных (db)**  
   - Образ: `postgres:16-alpine`  
   - Переменные окружения:
     - `POSTGRES_DB=booksdb`
     - `POSTGRES_USER=booksuser`
     - `POSTGRES_PASSWORD=bookspass`
   - Инициализация:
     - `db/schema.sql` — создание схемы.
     - `db/seed.sql` — начальные данные.
   - Порт: `5432`
   - Healthcheck через `pg_isready`.

2. **Backend (`books-backend`)**  
   - Образ: `oskalibriya/books-backend:latest`
   - Переменные окружения:
     - `DB_HOST=db`
     - `DB_PORT=5432`
     - `DB_NAME=booksdb`
     - `DB_USER=booksuser`
     - `DB_PASSWORD=bookspass`
   - Порт: `5000`
   - Зависит от здорового сервиса `db`.

3. **Frontend (`books-frontend`)**  
   - Образ: `oskalibriya/books-frontend:latest`
   - Порт: `80`
   - Отдаёт HTML‑страницу с заголовком `<h1>…</h1>`, который мы динамически меняем через ChatOps.
   - Файл `frontend/index.html` на сервере примонтирован в контейнер через Docker Volume, чтобы можно было обновлять заголовок без пересборки образа.

**Docker Compose (`books-app/docker-compose.yml`):**

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
Ключевой момент для ChatOps:

yaml
Copy
    volumes:
      - ./frontend/index.html:/usr/share/nginx/html/index.html
Благодаря этому контейнер использует актуальный index.html с файловой системы.

2.2 Архитектура инфраструктуры
Облако: AWS
ВМ: EC2 (Ubuntu)
Управление конфигурацией и деплой: Ansible
Контейнеризация: Docker + Docker Compose
Git‑репозиторий: GitHub (devops-book-app-project)
Высокоуровневая схема:

Ansible по SSH подключается к EC2.
Устанавливает Docker и Docker Compose.
Копирует необходимые файлы.
Запускает docker-compose для старта/обновления стека.
3. Используемые технологии
Git, GitHub — контроль версий и хранение кода.
GitHub Actions — CI/CD‑пайплайны.
Docker, Docker Compose — контейнеризация.
Ansible — автоматизация настройки и деплоя.
AWS EC2 — платформа исполнения.
PostgreSQL 16 — БД.
Python / Flask — backend (в контейнере).
Nginx + статический HTML — frontend.
Telegram Bot API — интерфейс ChatOps.
4. Дизайн CI/CD‑пайплайна
Проект использует несколько workflow‑ов GitHub Actions. Основной интерес — Step 3 – Ansible Deploy, который также дергается Telegram‑ботом.

4.1 Workflow: Step 3 – Ansible Deploy
Файл: .github/workflows/deploy.yml

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
            -d text="❌ *Deploy Failed! %0A⚠️ Check GitHub Actions logs: https://github.com/${{ github.repository }}/actions" \
            -d parse_mode="Markdown"
Основное:

Workflow запускается:
Автоматически после Step 2 (сборка и push Docker‑образов).
По workflow_dispatch — этот режим использует Telegram‑бот.
header_text меняет <h1>…</h1> в index.html через sed.
Изменения коммитятся и пушатся обратно в main.
Ansible деплоит обновлённую версию.
В Telegram отправляются уведомления.
5. Деплой через Ansible
Файл: deploy.yml (в корне репозитория):

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
Что делает:

Обновляет кеш пакетов.
Устанавливает Docker и Docker Compose.
Запускает и включает Docker.
Копирует:
SQL‑скрипты БД в /home/ubuntu/db/.
Файлы frontend в /home/ubuntu/frontend/.
docker-compose.yml в /home/ubuntu/docker-compose.yml.
Выполняет:
docker-compose down || true
docker-compose pull
docker-compose up -d
Контейнер фронтенда читает index.html из примонтированной директории.

6. Интеграция ChatOps (Telegram‑бот)
Высокоуровнево:

Пользователь в Telegram нажимает кнопку (например, «Change Header») и вводит новый текст.
Бот:
Вызывает GitHub Actions API workflow_dispatch для Step 3 - Ansible Deploy.
Передаёт:
header_text — текст заголовка.
triggered_by — маркер, что деплой инициирован ботом.
GitHub Actions:
Обновляет books-app/frontend/index.html.
Делает коммит и push.
Запускает Ansible.
По завершении workflow отправляет сообщение в Telegram через Bot API.
Получается замкнутый цикл ChatOps:
Telegram → GitHub → EC2 → Telegram.

7. Пошаговый процесс (команды и логика)
7.1 Локальный репозиторий
bash
Copy
git clone https://github.com/zaburdaev/devops-book-app-project.git
cd devops-book-app-project
Скопирована папка books-app из исходного репо курса.
Проверена структура (backend/, frontend/, db/, docker-compose.yml).
7.2 Настройка Docker Compose
Описали сервисы db, backend, frontend.
Добавили volume‑маппинги:
SQL‑скриптов schema.sql, seed.sql.
frontend/index.html для динамического обновления заголовка.
7.3 Создание Ansible‑плейбука
Файл deploy.yml:

Установка Docker и Docker Compose.
Копирование db/, frontend/ и docker-compose.yml на сервер.
Запуск docker-compose down/pull/up.
7.4 Создание GitHub Actions workflow (Step 3)
Файл .github/workflows/deploy.yml:

Триггеры:
workflow_run после Step 2.
workflow_dispatch (для Telegram‑бота).
sed‑замена заголовка в index.html.
Коммит и push изменений.
Настройка SSH и запуск Ansible.
Telegram‑уведомления через curl и Bot API.
7.5 Исправление ошибки прав git push в GitHub Actions
Ошибка:

text
Copy
Permission to ... denied to github-actions[bot].
Исправления:

В настройках репозитория:
Actions → General → Workflow permissions → Read and write permissions.
В job:
yaml
Copy
permissions:
  contents: write
В шаге checkout:
yaml
Copy
with:
  persist-credentials: true
Теперь github-actions[bot] может пушить коммиты.

7.6 Конфликты между локальными коммитами и коммитами бота
Ошибка:

text
Copy
! [rejected] main -> main (fetch first)
Updates were rejected because the remote contains work that you do not have locally.
Причина:

Бот коммитит в main, а локальная ветка отстаёт.
Решение:

bash
Copy
git pull --rebase origin main
git push origin main
8. Ошибки и их устранение
8.1 Заголовок не меняется на сайте
Симптом:

В Telegram — успешный деплой.
В GitHub Actions — всё зелёное.
На сайте заголовок не меняется.
Причина:

index.html внутри образа frontend не обновлялся.
Мы меняли файл только в репозитории.
Контейнер использовал "зашитую" версию index.html.
Решение:

Добавили volume для frontend:
yaml
Copy
frontend:
  ...
  volumes:
    - ./frontend/index.html:/usr/share/nginx/html/index.html
Добавили в Ansible копирование фронтенда на сервер:
yaml
Copy
- name: Copy frontend files to server
  copy:
    src: ./books-app/frontend/
    dest: /home/ubuntu/frontend/
Теперь при каждом деплое свежий index.html копируется на сервер и тут же подхватывается контейнером.

8.2 Ошибка 403 при git push из GitHub Actions
Ошибка:

text
Copy
remote: Permission to ... denied to github-actions[bot].
fatal: unable to access 'https://github.com/...'
Причина:

Токен GITHUB_TOKEN по умолчанию имел только права чтения.
Решение:

Включили write‑права в настройках Actions.
Добавили permissions: contents: write.
Настроили persist-credentials: true для actions/checkout.
8.3 Локальные ошибки non-fast-forward
Ошибка:

text
Copy
! [rejected] main -> main (fetch first)
Причина:

В удалённой ветке есть новые коммиты от бота.
Решение:

Всегда перед пушем:
bash
Copy
git pull --rebase origin main
git push origin main
9. Выводы и возможные улучшения
Что реализовано:

Полноценный CI/CD‑pipeline:
Docker‑образы backend и frontend.
Деплой на EC2 через Ansible и Docker Compose.
GitOps‑подход:
Все изменения (включая заголовок) проходят через Git.
ChatOps:
Telegram‑бот как интерфейс управления деплоем и контентом.
Возможные улучшения:

Добавить Terraform для автоматического создания EC2 и сетевой инфраструктуры.
Вынести чувствительные данные в облачное хранилище секретов.
Добавить автотесты после деплоя (curl‑чеки, health‑endpoint).
Расширить возможности бота:
Показ текущего заголовка.
Статус контейнеров (docker ps).
Отправка последних логов деплоя.
10. Использование ИИ и интеграция с DeepAgent
Проект был реализован при активной поддержке DeepAgent (Abacus.AI), который выступал в роли виртуального Senior DevOps инженера.

Как использовался ИИ
Проектирование архитектуры
DeepAgent помог спроектировать общий поток:
Telegram → GitHub → EC2 → Telegram.
Предложил использовать Docker Volumes для обновления контента без пересборки образов.
Отладка и troubleshooting
Выявил причину ошибок 403 при git push из GitHub Actions (недостаточные права).
Подсказал конкретные изменения в YAML (permissions, persist-credentials).
Помог понять, почему заголовок не менялся на сайте при успешном деплое (разница между файлами внутри образа и на хосте).
Генерация и улучшение кода
Участвовал в написании Ansible‑плейбука deploy.yml.
Помог структурировать workflow .github/workflows/deploy.yml с точки зрения лучших практик.
Работа с Git и конфликтами
Рекомендовал стратегию git pull --rebase origin main перед git push, чтобы корректно совмещать коммиты бота и локальную работу.
Ключевая задача, решённая с помощью ИИ
Главной технической проблемой была "статичность заголовка":

Заголовок не менялся, хотя:
Бот обновлял index.html в GitHub.
GitHub Actions успешно выполнялся.
Ansible завершался без ошибок.
DeepAgent объяснил, что:

Контейнер frontend использует index.html, "зашитый" в образ.
Обновлённый файл в репозитории не попадал внутрь контейнера.
Решение, предложенное ИИ:

Добавить монтирование index.html через Volume в docker-compose.yml.
Обеспечить копирование актуальных фронтенд‑файлов на сервер в Ansible перед запуском docker-compose up.
Это позволило сохранить преимущества контейнеризации и одновременно сделать контент динамическим и управляемым через ChatOps.