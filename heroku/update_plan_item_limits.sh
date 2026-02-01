#!/usr/bin/env bash
set -euo pipefail

APP_NAME=""
DRY_RUN="false"

usage() {
  cat 1>&2 <<'EOF'
Usage:
  heroku/update_plan_item_limits.sh -a <app> [--dry-run]

Updates plan item limits:
  - Professional: itemspermenu 150
  - Business:     itemspermenu 300

Options:
  -a, --app <name>   Heroku app name (required)
  --dry-run          Print what would change but do not write
  -h, --help         Show help

Example:
  ./heroku/update_plan_item_limits.sh -a smart-menus
  ./heroku/update_plan_item_limits.sh -a smart-menus --dry-run
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
    --dry-run)
      DRY_RUN="true"; shift ;;
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

echo "Target app: ${APP_NAME}"
echo "Dry run: ${DRY_RUN}"
echo ""

REMOTE_CMD=$(cat <<'BASH'
set -euo pipefail

cat > /tmp/update_plan_item_limits.rb <<'RUBY'
updates = {
  'plan.pro.key' => 150,
  'plan.business.key' => 300,
  'professional' => 150,
  'business' => 300,
}

dry_run = ENV['DRY_RUN'].to_s == 'true'

puts "DRY_RUN=#{dry_run}"

updates.each do |key, new_limit|
  plan = Plan.find_by(key: key)
  next unless plan

  old = plan.itemspermenu
  if old == new_limit
    puts "#{key}: already itemspermenu=#{old}"
    next
  end

  puts "#{key}: itemspermenu #{old.inspect} -> #{new_limit}"
  plan.update!(itemspermenu: new_limit) unless dry_run
end

puts 'Done.'
RUBY

DRY_RUN=${DRY_RUN} rails runner /tmp/update_plan_item_limits.rb
BASH
)

echo "Running on Heroku:"
echo "  DRY_RUN=${DRY_RUN} rails runner /tmp/update_plan_item_limits.rb"
echo ""

heroku run --app "${APP_NAME}" -- bash -lc "${REMOTE_CMD}"
