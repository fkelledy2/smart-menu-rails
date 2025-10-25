#!/bin/bash

# Script to regenerate WebP derivatives for all images in Heroku production
# This uses the existing GenerateImageDerivativesJob

set -e  # Exit on error

echo "========================================"
echo "WebP Derivative Regeneration Script"
echo "========================================"
echo ""

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "Error: Heroku CLI is not installed"
    echo "Install it from: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Get Heroku app name (default or from argument)
APP_NAME="${1:-smart-menus}"

echo "Target Heroku app: $APP_NAME"
echo ""

# Confirm before proceeding
read -p "This will regenerate WebP derivatives for ALL images. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Checking WebP conversion statistics..."
echo "----------------------------------------"
heroku run rake images:webp_stats --app "$APP_NAME"

echo ""
echo "Step 2: Starting WebP derivative regeneration..."
echo "----------------------------------------"
echo "This will queue background jobs for all menu images..."
echo "Jobs will be processed by Sidekiq workers."
echo ""

# Run the rake task on Heroku
heroku run rake images:regenerate_with_webp --app "$APP_NAME"

echo ""
echo "========================================"
echo "WebP Regeneration Jobs Queued!"
echo "========================================"
echo ""
echo "Background jobs have been queued in Sidekiq."
echo "Monitor progress:"
echo "  - Check Sidekiq dashboard in your app"
echo "  - Run: heroku run rake images:webp_stats --app $APP_NAME"
echo ""
echo "Alternative: For synchronous processing of menu items only:"
echo "  heroku run rake images:convert_to_webp --app $APP_NAME"
echo ""
