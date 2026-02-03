#!/usr/bin/env bash
set -euo pipefail

# Configure environment-specific variables for Staging
# Usage: heroku/staging/config.sh

APP_NAME="smart-menus-staging"

echo "==> Configuring Staging environment variables for ${APP_NAME}"

# Display current config (excluding sensitive values)
echo "==> Current configuration:"
heroku config -a "${APP_NAME}"

echo ""
echo "==> To set additional config vars, use:"
echo "    heroku config:set VARIABLE_NAME=value -a ${APP_NAME}"
echo ""
echo "==> Common variables to configure:"
echo "    - STRIPE_SECRET_KEY (test key)"
echo "    - STRIPE_WEBHOOK_SECRET (test webhook)"
echo "    - GOOGLE_MAPS_API_KEY"
echo "    - SENTRY_DSN (optional for error tracking)"
echo "    - GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET (OAuth)"
echo "    - APPLE_CLIENT_ID / APPLE_TEAM_ID / APPLE_KEY_ID / APPLE_P8_KEY (OAuth)"
