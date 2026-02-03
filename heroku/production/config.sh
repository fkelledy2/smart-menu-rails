#!/usr/bin/env bash
set -euo pipefail

# Configure environment-specific variables for Production
# Usage: heroku/production/config.sh

APP_NAME="smart-menus"

echo "==> Configuring Production environment variables for ${APP_NAME}"

# Display current config (excluding sensitive values)
echo "==> Current configuration:"
heroku config -a "${APP_NAME}"

echo ""
echo "==> To set additional config vars, use:"
echo "    heroku config:set VARIABLE_NAME=value -a ${APP_NAME}"
echo ""
echo "==> Common variables to configure:"
echo "    - STRIPE_SECRET_KEY (LIVE key)"
echo "    - STRIPE_WEBHOOK_SECRET (LIVE webhook)"
echo "    - GOOGLE_MAPS_API_KEY"
echo "    - SENTRY_DSN (recommended for error tracking)"
echo "    - GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET (OAuth)"
echo "    - APPLE_CLIENT_ID / APPLE_TEAM_ID / APPLE_KEY_ID / APPLE_P8_KEY (OAuth)"
echo ""
echo "==> ⚠️  Use LIVE/PRODUCTION keys only!"
