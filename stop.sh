#!/usr/bin/env bash
set -euo pipefail
source config.env
heroku ps:scale worker=0 web=0 -a "$APP_NAME"
