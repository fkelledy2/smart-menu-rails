#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/edit_credentials.sh [options]

Options:
  -e, --env ENV        Rails environment (development, test, production, etc.)
  --editor EDITOR      Editor command for Rails credentials (e.g. "code --wait", "vim")
  -h, --help           Show this help

Examples:
  scripts/edit_credentials.sh
  scripts/edit_credentials.sh --env production
  scripts/edit_credentials.sh --editor "code --wait"
  scripts/edit_credentials.sh --env production --editor "code --wait"

Notes:
  - This script does NOT print credentials.
  - It shells out to: bin/rails credentials:edit
EOF
}

ENVIRONMENT=""
EDITOR_CMD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENVIRONMENT="${2:-}"
      shift 2
      ;;
    --editor)
      EDITOR_CMD="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if [[ -n "$EDITOR_CMD" ]]; then
  export EDITOR="$EDITOR_CMD"
else
  export EDITOR="vi"
fi

if [[ -n "$ENVIRONMENT" ]]; then
  export RAILS_ENV="$ENVIRONMENT"
fi

if [[ ! -x "bin/rails" ]]; then
  echo "Error: bin/rails not found or not executable. Run from a Rails app root." >&2
  exit 1
fi

# Prefer explicit environment when provided; otherwise use default.
if [[ -n "$ENVIRONMENT" ]]; then
  exec bin/rails credentials:edit --environment "$ENVIRONMENT"
else
  exec bin/rails credentials:edit
fi
