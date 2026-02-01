#!/usr/bin/env bash
set -euo pipefail

APP_NAME=""
RESTAURANT_ID=""
USER_ID=""
RUN_ALL="false"

usage() {
  cat 1>&2 <<'EOF'
Usage:
  heroku/enforce_restaurant_menu_plan_limit.sh -a <app> --restaurant-id <id>
  heroku/enforce_restaurant_menu_plan_limit.sh -a <app> --user-id <id>
  heroku/enforce_restaurant_menu_plan_limit.sh -a <app> --all

Options:
  -a, --app <name>           Heroku app name (required)
  --restaurant-id <id>       Enforce for one restaurant
  --user-id <id>             Enforce for one user (all their restaurants)
  --all                      Enforce for all restaurants
  -h, --help                 Show help

Examples:
  ./heroku/enforce_restaurant_menu_plan_limit.sh -a smart-menus --restaurant-id 3
  ./heroku/enforce_restaurant_menu_plan_limit.sh -a smart-menus --user-id 123
  ./heroku/enforce_restaurant_menu_plan_limit.sh -a smart-menus --all
EOF
}

if ! command -v heroku >/dev/null 2>&1; then
  echo "Error: Heroku CLI is not installed" 1>&2
  echo "Install it from: https://devcenter.heroku.com/articles/heroku-cli" 1>&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--app)
      APP_NAME="${2:-}"; shift 2 ;;
    --restaurant-id)
      RESTAURANT_ID="${2:-}"; shift 2 ;;
    --user-id)
      USER_ID="${2:-}"; shift 2 ;;
    --all)
      RUN_ALL="true"; shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" 1>&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Error: --app is required" 1>&2
  usage
  exit 1
fi

modes=0
if [[ -n "$RESTAURANT_ID" ]]; then modes=$((modes+1)); fi
if [[ -n "$USER_ID" ]]; then modes=$((modes+1)); fi
if [[ "$RUN_ALL" == "true" ]]; then modes=$((modes+1)); fi

if [[ "$modes" -ne 1 ]]; then
  echo "Error: choose exactly one of --restaurant-id, --user-id, or --all" 1>&2
  usage
  exit 1
fi

RUNNER="EnforceRestaurantMenuPlanLimitJob.perform_now"
if [[ -n "$RESTAURANT_ID" ]]; then
  RUNNER="EnforceRestaurantMenuPlanLimitJob.perform_now(restaurant_id: ${RESTAURANT_ID})"
elif [[ -n "$USER_ID" ]]; then
  RUNNER="EnforceRestaurantMenuPlanLimitJob.perform_now(user_id: ${USER_ID})"
fi

CMD="rails runner '${RUNNER}'"

echo "Target app: ${APP_NAME}"
echo "Running: ${CMD}"
echo ""

heroku run "${CMD}" --app "${APP_NAME}"
