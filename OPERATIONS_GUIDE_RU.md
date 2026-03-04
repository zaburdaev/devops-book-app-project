### `OPERATIONS_GUIDE_RU.md` (Russian Version)

```markdown
# Руководство по эксплуатации: Books App DevOps
**Объединенный Runbook, Workbook и Руководство по устранению неполадок**

---

## 1. RUNBOOK (Инструкция по эксплуатации)
*Ежедневные задачи и использование системы.*

### 1.1 Доступ к приложению
- **Web UI:** `http://<SERVER_IP>` (Порт 80)
- **Backend API:** `http://<SERVER_IP>:5000/api/books`
- **База данных:** Доступна только внутри EC2 через Docker.

### 1.2 ChatOps: Обновление заголовка через Telegram
1. Откройте ваш Telegram-бот.
2. Отправьте команду (или нажмите кнопку) для смены заголовка.
3. Введите новый текст (например, "Добро пожаловать в магазин Виталия").
4. **Подождите 1-2 минуты**, пока завершится GitHub Action.
5. Обновите страницу в браузере.

### 1.3 Ручной перезапуск деплоя
Если нужно перезапустить приложение вручную на сервере:
```bash
ssh ubuntu@<SERVER_IP>
cd /home/ubuntu
docker-compose down
docker-compose pull
docker-compose up -d
2. WORKBOOK (Как это было построено)
Техническая история и этапы реализации.

2.1 Инфраструктура и безопасность
Облако: AWS EC2 (Ubuntu 22.04).
Security Groups: Открыты порты 22 (SSH), 80 (HTTP), 5000 (API).
SSH: Сгенерированы ключи RSA 4096 для безопасной связи GitHub -> EC2.
2.2 Логика CI/CD пайплайна
Шаг 1 (Terraform): Создание ресурсов (Опционально).
Шаг 2 (Docker): Сборка и Push образов в Docker Hub (oskalibriya/books-*).
Шаг 3 (Ansible):
Запускается после Шага 2 или через Telegram-бота.
Обновляет index.html через sed.
Делает коммит в Git.
Запускает Ansible Playbook для синхронизации файлов и перезапуска контейнеров.
3. TROUBLESHOOTING (Решение проблем)
Типичные ошибки и проверенные решения.

Ошибка	Симптом	Решение
Git Push 403	Permission denied в GitHub Actions	Включить "Read and write permissions" в Settings > Actions.
Заголовок не меняется	Успех в логах, но старый текст на сайте	Проверить volumes в docker-compose.yml и копирование файлов в Ansible.
Конфликт Git	! [rejected] main -> main	Выполнить git pull --rebase origin main перед пушем.
SSH Timeout	Экшен зависает на шаге Ansible	Проверить секрет SERVER_IP и наличие ssh-keyscan в воркфлоу.
4. Использование ИИ (Интеграция с DeepAgent)
Проект разработан при поддержке DeepAgent (Abacus.AI).

Стратегический вклад:

Архитектура: Проектирование цикла ChatOps (Telegram -> GitHub -> EC2).
Оптимизация: Внедрение стратегии Volume Mount для мгновенных обновлений.
Решение задач: Устранение сложных проблем с правами доступа и синхронизацией Git