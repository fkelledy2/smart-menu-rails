#!/usr/bin/env bash
set -euo pipefail

# Tail worker logs for Production environment
# Usage: heroku/production/tail-workers.sh [options]
# Additional options are passed through to `heroku logs`

APP_NAME="smart-menus"

echo "==> Tailing worker logs for Production: ${APP_NAME}"
echo "==> Press Ctrl+C to stop"
echo ""

heroku logs --tail --ps worker -a "${APP_NAME}" "$@"
