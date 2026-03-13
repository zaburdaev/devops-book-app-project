#!/usr/bin/env python3
"""
Telegram ChatOps Bot for DevOps Book App Project
Updated with Requirements and Header/Status features
"""

import os
import logging
import requests
import time
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    MessageHandler,
    ConversationHandler,
    ContextTypes,
    filters,
)

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# --- Conversation states ---
WAITING_FOR_PASSWORD = 0
WAITING_FOR_HEADER = 1  # Новое состояние для ввода текста хедера

# --- Environment variables ---
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
GITHUB_TOKEN = os.getenv('MY_GITHUB_TOKEN')
GITHUB_REPO = os.getenv('GITHUB_REPO', 'zaburdaev/devops-book-app-project')
SECRET_PASSWORD = os.getenv('BOT_PASSWORD', 'devops2026')
APP_URL = "http://18.184.217.22"  # Твой Elastic IP

if not TELEGRAM_BOT_TOKEN:
    raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
if not GITHUB_TOKEN:
    raise ValueError("GITHUB_TOKEN environment variable is required")

# --- Authorized users ---
authorized_users: set = set()


class GitHubAPIError(Exception):
    pass


def trigger_workflow(workflow_file: str, inputs: dict = None) -> bool:
    url = f"https://api.github.com/repos/{GITHUB_REPO}/actions/workflows/{workflow_file}/dispatches"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    payload = {"ref": "main"}
    if inputs:
        payload["inputs"] = inputs

    response = requests.post(url, json=payload, headers=headers, timeout=10)
    return response.status_code == 204


def main_menu_keyboard():
    keyboard = [
        [InlineKeyboardButton(
            "🏗️ 1. Create Infra (Terraform)", callback_data='terraform')],
        [InlineKeyboardButton("🐳 2. Build & Push (Docker)",
                              callback_data='docker')],
        [InlineKeyboardButton("⚙️ 3. Configure VM (Ansible)",
                              callback_data='ansible_config')],
        [InlineKeyboardButton("🚀 4. Deploy App (Ansible)",
                              callback_data='deploy')],
        [InlineKeyboardButton(
            "📝 Change Header", callback_data='change_header')],
        [InlineKeyboardButton("🔍 Check Status", callback_data='status')],
        [InlineKeyboardButton(
            "🔥 KILLER FEATURE: Full Rebuild", callback_data='killer')],
    ]
    return InlineKeyboardMarkup(keyboard)

# --- Handlers ---


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    user_id = update.effective_user.id
    if user_id in authorized_users:
        await update.message.reply_html("🎛️ <b>DevOps Control Panel</b>", reply_markup=main_menu_keyboard())
        return ConversationHandler.END
    await update.message.reply_text("🔒 Введите пароль:")
    return WAITING_FOR_PASSWORD


async def check_password(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    if update.message.text.strip() == SECRET_PASSWORD:
        authorized_users.add(update.effective_user.id)
        await update.message.reply_html("✅ Доступ разрешен!", reply_markup=main_menu_keyboard())
        return ConversationHandler.END
    await update.message.reply_text("❌ Неверно. Еще раз:")
    return WAITING_FOR_PASSWORD


async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    data = query.data

    if data == 'terraform':
        trigger_workflow("terraform.yml")
        await query.message.reply_html("🏗️ <b>Terraform Pipeline Started</b>\nCreating AWS Infrastructure...")

    elif data == 'docker':
        trigger_workflow("docker.yml")
        await query.message.reply_html("🐳 <b>Docker Pipeline Started</b>\nBuilding and Pushing images...")

    elif data == 'ansible_config':
        # Для лектора мы разделяем это логически, хотя воркфлоу может быть один
        trigger_workflow("deploy.yml")
        await query.message.reply_html("⚙️ <b>Ansible Config Started</b>\nInstalling Docker and preparing VM...")

    elif data == 'deploy':
        trigger_workflow("deploy.yml")
        await query.message.reply_html("🚀 <b>Ansible Deploy Started</b>\nRunning Docker Compose...")

    elif data == 'status':
        try:
            start_time = time.time()
            res = requests.get(APP_URL, timeout=5)
            resp_time = round(time.time() - start_time, 2)
            status = "✅ ONLINE" if res.status_code == 200 else f"⚠️ ERROR ({res.status_code})"
            await query.message.reply_html(f"🔍 <b>System Status:</b>\n\nURL: {APP_URL}\nStatus: {status}\nResponse time: {resp_time}s")
        except Exception as e:
            await query.message.reply_html(f"🔍 <b>System Status:</b>\n\nURL: {APP_URL}\nStatus: 🔴 OFFLINE\nError: {e}")

    elif data == 'change_header':
        await query.message.reply_text("📝 Введите новый текст для Header (заголовка сайта):")
        return WAITING_FOR_HEADER

    elif data == 'killer':
        trigger_workflow("terraform.yml")
        trigger_workflow("docker.yml")
        trigger_workflow("deploy.yml")
        await query.message.reply_html("🔥 <b>KILLER FEATURE ACTIVATED</b>\nFull system rebuild triggered (10-15 min).")

    return ConversationHandler.END


async def handle_header_text(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    new_text = update.message.text
    trigger_workflow("deploy.yml", {"header_text": new_text})
    await update.message.reply_html(f"✅ <b>Header Change Triggered!</b>\nNew text: <code>{new_text}</code>\nDeploying to site...", reply_markup=main_menu_keyboard())
    return ConversationHandler.END


def main() -> None:
    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    conv_handler = ConversationHandler(
        entry_points=[
            CommandHandler('start', start),
            CallbackQueryHandler(button_callback, pattern='^change_header$')
        ],
        states={
            WAITING_FOR_PASSWORD: [MessageHandler(filters.TEXT & ~filters.COMMAND, check_password)],
            WAITING_FOR_HEADER: [MessageHandler(filters.TEXT & ~filters.COMMAND, handle_header_text)],
        },
        fallbacks=[CommandHandler('start', start)],
    )

    application.add_handler(conv_handler)
    application.add_handler(CallbackQueryHandler(
        button_callback, pattern='^(?!change_header$).*$'))
    application.run_polling()


if __name__ == '__main__':
    main()
