#!/usr/bin/env bash
set -euo pipefail

if [ ! -f config.env ]; then
  echo "❌ ملف config.env غير موجود."
  exit 1
fi

set -a
source config.env
set +a

if [ -z "${APP_NAME:-}" ]; then
  echo "❌ APP_NAME غير موجود داخل config.env"
  exit 1
fi

if [ -z "${XMR_WALLET:-}" ] || [[ "$XMR_WALLET" == *"PUT_YOUR"* ]]; then
  echo "❌ افتح config.env وضع عنوان محفظة XMR في XMR_WALLET أولاً."
  echo "nano config.env"
  exit 1
fi

if ! command -v heroku >/dev/null 2>&1; then
  echo "❌ heroku CLI غير مثبت أو غير موجود في PATH."
  echo "ثبته ثم أعد التشغيل."
  exit 1
fi

if ! heroku auth:whoami >/dev/null 2>&1; then
  echo "🔐 سجل دخولك إلى Heroku..."
  heroku login
fi

# تأكد أن المشروع يستخدم Python buildpack وليس container stack
heroku stack:set heroku-24 -a "$APP_NAME" || true
heroku buildpacks:clear -a "$APP_NAME" || true
heroku buildpacks:set heroku/python -a "$APP_NAME"

# ضع القيم في Config Vars حتى لا تعتمد على الملفات داخل الريبو
heroku config:set \
  XMR_WALLET="$XMR_WALLET" \
  XMR_POOL="${XMR_POOL:-pool.supportxmr.com:3333}" \
  WORKER_NAME="${WORKER_NAME:-heroku1}" \
  XMR_THREADS="${XMR_THREADS:-2}" \
  XMR_DONATE_LEVEL="${XMR_DONATE_LEVEL:-1}" \
  -a "$APP_NAME"

# جهز git
if [ ! -d .git ]; then
  git init
fi

git add Procfile requirements.txt run_miner.py README_AR.md config.env deploy.sh logs.sh stop.sh quick_start.sh 2>/dev/null || true
if git diff --cached --quiet; then
  echo "ℹ️ لا توجد تغييرات جديدة في git، سيتم محاولة الدفع كما هو."
else
  git commit -m "deploy authorized worker" || true
fi

heroku git:remote -a "$APP_NAME" || true

# push إلى الفرع الرئيسي الحالي أو main
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if [ -z "$BRANCH" ]; then
  BRANCH="main"
fi

git push heroku HEAD:main

# شغّل worker وأوقف web لأنه لا يوجد موقع ويب
heroku ps:scale worker=1 web=0 -a "$APP_NAME"

echo "✅ تم النشر. راقب السجل الآن:"
echo "heroku logs --tail -a $APP_NAME"
heroku logs --tail -a "$APP_NAME"
