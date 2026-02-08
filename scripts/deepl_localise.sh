#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/deepl_localise.sh [LOCALE] [options]

Arguments:
  LOCALE               Optional locale folder name under config/locales (e.g. cs, fr, it)

Options:
  --dry-run            Do not write files
  --limit N            Limit number of replacements per locale (debug)
  --show               Print each replacement as from(old) to(new)
  -h, --help           Show help

Notes:
  - This script does NOT require DEEPL_API_KEY.
  - The DeepL key is read from Rails credentials first:
      deepl:
        api_key: "..."
    (ENV DEEPL_API_KEY is still accepted as an override)
EOF
}

ARGS=()
LOCALE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      ARGS+=("--dry-run")
      shift
      ;;
    --limit)
      ARGS+=("--limit" "${2:-}")
      shift 2
      ;;
    --show)
      ARGS+=("--show")
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${LOCALE}" && "$1" =~ ^[A-Za-z_]+$ ]]; then
        LOCALE="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if [[ -n "${LOCALE}" ]]; then
  ARGS+=("--locale" "${LOCALE}")
fi

if [[ ${#ARGS[@]} -gt 0 ]]; then
  exec ruby scripts/deepl_translate_duplicates.rb "${ARGS[@]}"
else
  exec ruby scripts/deepl_translate_duplicates.rb
fi
