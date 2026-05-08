#!/usr/bin/env bash
set -euo pipefail
source config.env
heroku stack:set heroku-24 -a "$APP_NAME" || true
heroku buildpacks:clear -a "$APP_NAME" || true
heroku buildpacks:set heroku/python -a "$APP_NAME"
heroku config:set XMR_WALLET="$XMR_WALLET" XMR_POOL="$XMR_POOL" WORKER_NAME="$WORKER_NAME" XMR_THREADS="$XMR_THREADS" XMR_DONATE_LEVEL="$XMR_DONATE_LEVEL" -a "$APP_NAME"
git init || true
git add .
git commit -m "deploy authorized worker" || true
heroku git:remote -a "$APP_NAME" || true
git push heroku HEAD:main
heroku ps:scale worker=1 web=0 -a "$APP_NAME"
