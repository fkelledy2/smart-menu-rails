#!/usr/bin/env bash
set -euo pipefail

# Deploy to Heroku Development Environment
# Usage: heroku/dev/deploy.sh [branch]

APP_NAME="smart-menus-dev"
BRANCH="${1:-main}"

echo "==> Deploying to Development: ${APP_NAME}"
echo "==> Branch: ${BRANCH}"

# Push to Heroku
echo "==> Pushing code to Heroku..."
git push "https://git.heroku.com/${APP_NAME}.git" "${BRANCH}:main"

# Wait for release
echo "==> Waiting for release to complete..."
sleep 5

# Show recent logs
echo "==> Recent logs:"
heroku logs --tail --num=50 -a "${APP_NAME}"
