#!/usr/bin/env bash
set -euo pipefail

# Tail logs for Staging environment
# Usage: heroku/staging/tail.sh [options]
# Options: --ps web|worker|all, --source app|heroku, etc.

APP_NAME="smart-menus-staging"

echo "==> Tailing logs for Staging: ${APP_NAME}"
echo "==> Press Ctrl+C to stop"
echo ""

# Pass all arguments to heroku logs command
heroku logs --tail -a "${APP_NAME}" "$@"
