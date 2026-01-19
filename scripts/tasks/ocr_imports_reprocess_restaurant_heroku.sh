#!/bin/bash

# Run OCR import reprocess for a single restaurant on Heroku.
# Wraps: rake ocr_imports:reprocess_restaurant[12,,false]
#
# Usage:
#   ./scripts/tasks/ocr_imports_reprocess_restaurant_heroku.sh [-a|--app|--aap APP_NAME] [RESTAURANT_ID] [LIMIT] [DRY_RUN]
#
# Examples:
#   ./scripts/tasks/ocr_imports_reprocess_restaurant_heroku.sh -a smart-menus 12 '' false
#   ./scripts/tasks/ocr_imports_reprocess_restaurant_heroku.sh --app smart-menus-staging 12 2 true
#
# Notes:
# - LIMIT can be empty to mean "no limit".
# - DRY_RUN should be true/false.

set -euo pipefail

APP_NAME=""
RESTAURANT_ID="12"
LIMIT=""
DRY_RUN="false"

usage() {
  echo "Usage: $0 [-a|--app|--aap APP_NAME] [RESTAURANT_ID] [LIMIT] [DRY_RUN]" 1>&2
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--app|--aap)
      if [[ $# -lt 2 ]]; then
        echo "Error: missing value for $1" 1>&2
        usage
        exit 1
      fi
      APP_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Error: unknown option: $1" 1>&2
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# Positional args
if [[ $# -ge 1 ]]; then RESTAURANT_ID="$1"; fi
if [[ $# -ge 2 ]]; then LIMIT="$2"; fi
if [[ $# -ge 3 ]]; then DRY_RUN="$3"; fi

# Basic checks
if ! command -v heroku >/dev/null 2>&1; then
  echo "Error: Heroku CLI is not installed" 1>&2
  echo "Install it from: https://devcenter.heroku.com/articles/heroku-cli" 1>&2
  exit 1
fi

if [[ -z "$APP_NAME" ]]; then
  # Default app name; override with -a/--app
  APP_NAME="smart-menus"
fi

if [[ -z "$RESTAURANT_ID" ]]; then
  echo "Error: RESTAURANT_ID is required" 1>&2
  usage
  exit 1
fi

# Compose rake invocation
RAKE_TASK="ocr_imports:reprocess_restaurant[$RESTAURANT_ID,$LIMIT,$DRY_RUN]"

echo "Target app: $APP_NAME"
echo "Running: bundle exec rake $RAKE_TASK"
echo ""

heroku run "bundle exec rake $RAKE_TASK" --app "$APP_NAME"
