#!/usr/bin/env bash
set -euo pipefail

# Heroku Staging Environment Setup
# Usage: heroku/staging/setup.sh

APP_NAME="smart-menus-staging"
REGION="eu"
STACK="heroku-22"

echo "==> Setting up Heroku Staging Environment: ${APP_NAME}"

# Create app if it doesn't exist
if ! heroku apps:info -a "${APP_NAME}" >/dev/null 2>&1; then
  echo "==> Creating Heroku app: ${APP_NAME}"
  heroku create "${APP_NAME}" --region "${REGION}" --stack "${STACK}"
else
  echo "==> App ${APP_NAME} already exists"
fi

# Set buildpacks
echo "==> Configuring buildpacks"
heroku buildpacks:clear -a "${APP_NAME}"
heroku buildpacks:add heroku/nodejs -a "${APP_NAME}"
heroku buildpacks:add heroku/ruby -a "${APP_NAME}"

# Add-ons
echo "==> Provisioning add-ons"
heroku addons:create heroku-postgresql:standard-0 -a "${APP_NAME}" || echo "PostgreSQL already exists"
heroku addons:create heroku-redis:premium-0 -a "${APP_NAME}" || echo "Redis already exists"
heroku addons:create bucketeer:hobbyist -a "${APP_NAME}" || echo "Bucketeer already exists"

# Config vars
echo "==> Setting config vars"
heroku config:set \
  RAILS_ENV=staging \
  RACK_ENV=staging \
  NODE_ENV=production \
  RAILS_LOG_LEVEL=info \
  DISABLE_CACHE=false \
  USE_S3_STORAGE=true \
  -a "${APP_NAME}"

# Set master key if available
if [[ -f "config/master.key" ]]; then
  heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)" -a "${APP_NAME}"
else
  echo "WARN: config/master.key not found. Set RAILS_MASTER_KEY manually."
fi

echo "==> Staging environment setup complete!"
echo "==> Next steps:"
echo "    1. Set additional config vars (Stripe, Google Maps, etc.)"
echo "    2. Deploy: git push https://git.heroku.com/${APP_NAME}.git main"
echo "    3. Run migrations: heroku run rails db:migrate -a ${APP_NAME}"
