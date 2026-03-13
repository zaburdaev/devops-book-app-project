# DEVOPS PROJECT STATE – Books App (Lecturer: Andrius Solovej)

## 1. Общая идея проекта

Проект – учебный DevOps-проект по развёртыванию трёхзвённого приложения **Books App**:

- **Frontend** – статический сайт (HTML/CSS/JS, Nginx), показывает список книг и header.
- **Backend** – Python Flask API, работает с книгами.
- **DB** – PostgreSQL.

Задача: построить **полный CI/CD-пайплайн** с использованием:
- **AWS EC2** (через Terraform),
- **Docker** (контейнеризация),
- **Docker Hub** (registry),
- **Ansible** (подготовка VM и деплой),
- **GitHub Actions** (CI/CD),
- плюс **Telegram ChatOps Bot** для управления пайплайнами.

---

## 2. Репозитории

### 2.1. Репозиторий лектора (исходный код)

- **Books App (исходник)**:  
  [https://github.com/serbent/ca-DevOpsUA6/tree/main/books-app](https://github.com/serbent/ca-DevOpsUA6/tree/main/books-app)

Содержит:
- `frontend/` – код фронтенда
- `backend/` – код бэкенда
- `db/` – SQL/инициализация БД
- `docker-compose.yml`
- `README.md` с требованиями к DevOps-проекту

### 2.2. Личный DevOps-репозиторий студента

(НАЗВАНИЕ ЗДЕСЬ ЗАМЕНИ НА ФАКТИЧЕСКОЕ, ЕСЛИ ДРУГОЕ)

- **DevOps репозиторий**:  
  `https://github.com/zaburdaev/devops-book-app-project` (пример, уточнить фактический URL)

Структура (целевое состояние):
- `books-app/` – скопированный код приложения из репо лектора
- `terraform/` – код Terraform для создания AWS-инфраструктуры
- `ansible/` – плейбуки для настройки VM и деплоя
- `.github/workflows/`
  - `terraform.yml` – CI/CD для Terraform
  - `docker.yml` – CI/CD для сборки/публикации Docker-образов
  - `deploy.yml` – CI/CD для Ansible + деплоя
- `telegram_bot/` (локально на сервере, в репозитории может быть или нет)
  - `main.py` – Telegram ChatOps Bot (фактический файл на EC2: `/home/ubuntu/telegram_bot/main.py`)

---

## 3. Инфраструктура (AWS)

### 3.1. Целевое состояние

- **1 EC2 instance** (Ubuntu, t2.micro/t3.micro):
  - Порты:
    - `22` – SSH
    - `80` – HTTP (Nginx frontend)
    - `5000` – backend (может быть только внутри Docker сети)
  - Docker + Docker Compose установлены Ansible-ом.
  - Приложение развёрнуто через `docker compose`.

- **Elastic IP** (публичный адрес приложения):
  - Текущий IP:  
    `http://18.184.217.22`
  - Доступен из интернета, используется:
    - для проверки статуса в Telegram-боте,
    - для проверки преподавателем.

---

## 4. Docker и Docker Hub

### 4.1. Образы

Задумка:
- `DOCKERHUB_USERNAME/books-frontend:latest`
- `DOCKERHUB_USERNAME/books-backend:latest`

Сборка и пуш:
- выполняются из GitHub Actions workflow `docker.yml`.

(Точный DOCKERHUB_USERNAME и имена образов нужно подставить по факту.)

---

## 5. GitHub Actions Workflows

### 5.1. `terraform.yml`

Назначение:
- Запуск Terraform:
  - `terraform init`
  - `terraform plan`
  - `terraform apply -auto-approve`
- Создание/обновление:
  - EC2 instance,
  - Security Group (порты 22/80/5000),
  - Elastic IP и привязка к EC2.

### 5.2. `docker.yml`

Назначение:
- Сборка Docker-образов frontend и backend.
- Логин в Docker Hub.
- Публикация образов.

### 5.3. `deploy.yml`

Назначение:
- Запуск Ansible:
  - Установка Docker/Docker Compose на EC2.
  - Клонирование/обновление кода или копирование `docker-compose.yml`.
  - `docker compose pull` и `docker compose up -d`.
- Используется также для:
  - смены Header через input `header_text` (workflow_dispatch).

---

## 6. Telegram ChatOps Bot

Бот развернут на той же EC2 или на отдельном сервере:

- Локальный путь:  
  `/home/ubuntu/telegram_bot/main.py`

- Использует:
  - `python-telegram-bot` (версия 20+ c async API),
  - `requests`.

### 6.1. Переменные окружения

- `TELEGRAM_BOT_TOKEN` – токен бота.
- `GITHUB_TOKEN` – GitHub Personal Access Token с правами на `workflow`.
- `GITHUB_REPO` – репозиторий с DevOps-пайплайнами, по умолчанию:  
  `zaburdaev/devops-book-app-project`
- `BOT_PASSWORD` – пароль для доступа к панелям (по умолчанию: `devops2026`).
- `APP_URL` – URL фронтенда для проверки статуса, например:  
  `http://18.184.217.22`

### 6.2. Логика бота

#### Авторизация

- Команда `/start`:
  - если пользователь **ещё не авторизован** → бот просит пароль → состояние `WAITING_FOR_PASSWORD`.
  - если авторизован → сразу показывает главное меню.

- `WAITING_FOR_PASSWORD`:
  - если введён текст == `BOT_PASSWORD`:
    - пользователь добавляется в `authorized_users`,
    - показывается главное меню.
  - иначе → «неверно, попробуйте ещё раз».

#### Главное меню (InlineKeyboard)

Кнопки:

1. `🏗️ 1. Create Infra (Terraform)` → callback_data=`terraform`
   - `trigger_workflow("terraform.yml")`

2. `🐳 2. Build & Push (Docker)` → callback_data=`docker`
   - `trigger_workflow("docker.yml")`

3. `⚙️ 3. Configure VM (Ansible)` → callback_data=`ansible_config`
   - логически «конфигурация VM», технически:
   - `trigger_workflow("deploy.yml")` (Ansible часть)

4. `🚀 4. Deploy App (Ansible)` → callback_data=`deploy`
   - `trigger_workflow("deploy.yml")` (деплой Docker Compose)

5. `📝 Change Header` → callback_data=`change_header`
   - запускает диалог смены заголовка:
     - бот просит ввести новый текст,
     - ждёт текст в состоянии `WAITING_FOR_HEADER`,
     - после ввода вызывает `trigger_workflow("deploy.yml", {"header_text": new_text})`.

6. `🔍 Check Status` → callback_data=`status`
   - отправляет HTTP GET на `APP_URL`,
   - измеряет время ответа,
   - выводит ONLINE/OFFLINE + статус-код и время ответа.

7. `🔥 KILLER FEATURE: Full Rebuild` → callback_data=`killer`
   - по очереди вызывает:
     - `trigger_workflow("terraform.yml")`
     - `trigger_workflow("docker.yml")`
     - `trigger_workflow("deploy.yml")`
   - Фактически «полный rebuild» всего окружения.

### 6.3. Состояния ConversationHandler

- `WAITING_FOR_PASSWORD`:
  - ловит любой текст (не команду),
  - проверяет пароль,
  - пускает к кнопкам или просит повтор.

- `WAITING_FOR_HEADER`:
  - ловит текст после нажатия `📝 Change Header`,
  - вызывает `handle_header_text()`:
    - `trigger_workflow("deploy.yml", {"header_text": new_text})`,
    - отвечает сообщением, что деплой с новым header запущен,
    - показывает главное меню.

---

## 7. Текущие ключевые моменты

- **Бот работает**: все кнопки + смена header.
- **Header change**:
  - реализован через GitHub Actions `deploy.yml` с input `header_text`.
  - триггерится как:
    - через Telegram бота,
    - так и вручную через `workflow_dispatch` в GitHub Actions.

- **Мониторинг**:
  - простая проверка `APP_URL` через запрос с timeout 5 секунд.

---

## 8. Что можно улучшить в будущем (идеи)

- Добавить:
  - нотификации в Telegram о завершении GitHub Actions (через webhook или через периодический опрос статуса пайплайна).
  - роль «только чтение» для пользователей, которые могут смотреть статус, но не запускать деплой.
- Вынести настройки (IP, репо, имена workflow) в config-файл.
- Добавить healthcheck backend’а (например, `/health` на 5000 порту).
