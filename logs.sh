#!/usr/bin/env bash
set -euo pipefail
source config.env
heroku logs --tail -a "$APP_NAME"
