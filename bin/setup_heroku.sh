#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bin/setup_heroku.sh <app-name> [--region eu|us] [--stack heroku-22|heroku-24]
# Example:
#   bin/setup_heroku.sh smart-menu-rails --region eu --stack heroku-22

APP_NAME=${1:-}
REGION="us"
STACK="heroku-22"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"; shift 2 ;;
    --stack)
      STACK="$2"; shift 2 ;;
    *)
      if [[ -z "${APP_NAME}" ]]; then APP_NAME="$1"; shift; else shift; fi ;;
  esac
done

if [[ -z "${APP_NAME}" ]]; then
  echo "ERROR: app name required."
  echo "Usage: bin/setup_heroku.sh <app-name> [--region eu|us] [--stack heroku-22|heroku-24]"
  exit 1
fi

if ! command -v heroku >/dev/null 2>&1; then
  echo "ERROR: heroku CLI not found. Install from https://devcenter.heroku.com/articles/heroku-cli"
  exit 1
fi

echo "==> Creating Heroku app: ${APP_NAME} (region=${REGION}, stack=${STACK})"
heroku create "${APP_NAME}" --region "${REGION}" --stack "${STACK}" || true

# Ensure correct buildpack ordering
echo "==> Setting buildpacks (nodejs first, then ruby)"
heroku buildpacks:add heroku/nodejs -a "${APP_NAME}" --index 1 || true
heroku buildpacks:add heroku/ruby   -a "${APP_NAME}" --index 2 || true

# Add-ons
echo "==> Provisioning add-ons"
heroku addons:create heroku-postgresql:essential -a "${APP_NAME}" || true
heroku addons:create heroku-redis:mini          -a "${APP_NAME}" || true

# Config vars
echo "==> Setting config vars"
if [[ -f "config/master.key" ]]; then
  heroku config:set RAILS_MASTER_KEY="$(cat config/master.key)" -a "${APP_NAME}"
else
  echo "WARN: config/master.key not found; set RAILS_MASTER_KEY manually."
fi

heroku config:set RAILS_ENV=production NODE_ENV=production -a "${APP_NAME}"

# REDIS_URL is usually set automatically by the add-on; ensure it's present
if ! heroku config:get REDIS_URL -a "${APP_NAME}" >/dev/null 2>&1; then
  echo "WARN: REDIS_URL not set yet. It may populate shortly after add-on creation."
fi

# Recommended: set host for mailers/rails url helpers if you have a custom domain
# heroku config:set HOST="${APP_NAME}.herokuapp.com" -a "${APP_NAME}"

# Confirm stack (optional switch)
heroku stack:set "${STACK}" -a "${APP_NAME}" || true

# Push code (expects main branch)
echo "==> Pushing code to Heroku (main)"
if git rev-parse --verify main >/dev/null 2>&1; then
  git push "https://git.heroku.com/${APP_NAME}.git" main
else
  echo "WARN: No 'main' branch found. Push your current branch manually:"
  echo "  git push https://git.heroku.com/${APP_NAME}.git HEAD:main"
fi

# Run migrations via release phase; also provide manual fallback
echo "==> Release phase will run db:migrate automatically. Manual fallback:"
echo "  heroku run rails db:migrate -a ${APP_NAME}"

echo "==> Logs (Ctrl+C to exit)"
heroku logs --tail -a "${APP_NAME}"
