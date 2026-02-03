#!/usr/bin/env bash
set -euo pipefail

# Tail logs for Production environment
# Usage: heroku/production/restart.sh [options]

APP_NAME="smart-menus"

echo "==> Restart Production: ${APP_NAME}"
echo "==> Press Ctrl+C to stop"
echo ""

# Pass all arguments to heroku logs command
heroku ps:restart -a "${APP_NAME}" "$@"
