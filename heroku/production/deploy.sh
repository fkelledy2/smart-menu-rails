#!/usr/bin/env bash
set -euo pipefail

# Deploy to Heroku Production Environment
# Usage: heroku/production/deploy.sh [branch]

APP_NAME="smart-menus"
BRANCH="${1:-main}"

echo "==> ⚠️  PRODUCTION DEPLOYMENT ⚠️"
echo "==> App: ${APP_NAME}"
echo "==> Branch: ${BRANCH}"
echo ""
read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm

if [[ "${confirm}" != "yes" ]]; then
  echo "==> Deployment cancelled"
  exit 0
fi

# Push to Heroku
echo "==> Pushing code to Heroku..."
git push "https://git.heroku.com/${APP_NAME}.git" "${BRANCH}:main"

# Wait for release
echo "==> Waiting for release to complete..."
sleep 10

# Show recent logs
echo "==> Recent logs:"
heroku logs --tail --num=50 -a "${APP_NAME}"
