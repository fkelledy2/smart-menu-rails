#!/usr/bin/env bash
set -euo pipefail

# Tail logs for Production environment
# Usage: heroku/production/tail.sh [options]
# Options: --ps web|worker|all, --source app|heroku, etc.

APP_NAME="smart-menus"

echo "==> Tailing logs for Production: ${APP_NAME}"
echo "==> Press Ctrl+C to stop"
echo ""

# Pass all arguments to heroku logs command
heroku logs --tail -a "${APP_NAME}" "$@"
