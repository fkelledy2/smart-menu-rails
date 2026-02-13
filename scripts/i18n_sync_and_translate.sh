#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# i18n Sync & Translate
# =============================================================================
# A single script that covers all i18n maintenance tasks:
#
#   1. Check for missing translation keys (i18n-tasks missing)
#   2. Copy missing keys from en/ into each locale with "replace_me" placeholder
#   3. Normalize locale files (i18n-tasks normalize)
#   4. Translate all "replace_me" strings via DeepL
#
# Usage:
#   scripts/i18n_sync_and_translate.sh [options]
#
# Options:
#   --check-only         Only run steps 1 (report missing) — no file changes
#   --sync-only          Run steps 1-3 (sync + normalize) — skip DeepL translation
#   --locale LOCALE      Only process a single locale (e.g. fr, it, cs)
#   --dry-run            Pass --dry-run to the DeepL translation step
#   --show               Pass --show to the DeepL translation step (print replacements)
#   -h, --help           Show this help
# =============================================================================

usage() {
  sed -n '/^# =====/,/^# =====/{ /^# =====/d; s/^# //; s/^#$//; p }' "$0" | head -n -1
}

CHECK_ONLY=false
SYNC_ONLY=false
LOCALE=""
DEEPL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only)   CHECK_ONLY=true; shift ;;
    --sync-only)    SYNC_ONLY=true; shift ;;
    --locale)       LOCALE="${2:-}"; shift 2 ;;
    --dry-run)      DEEPL_ARGS+=("--dry-run"); shift ;;
    --show)         DEEPL_ARGS+=("--show"); shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCALES_ROOT="$PROJECT_ROOT/config/locales"

cd "$PROJECT_ROOT"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No colour

step() { echo -e "\n${BLUE}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}  ✔ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
fail() { echo -e "${RED}  ✘ $1${NC}"; }

# ---------------------------------------------------------------------------
# Step 1: Check for missing translation keys
# ---------------------------------------------------------------------------
step "Step 1/4 — Checking for missing translation keys"

MISSING_OUTPUT=$(bundle exec i18n-tasks missing 2>&1 || true)

if echo "$MISSING_OUTPUT" | grep -q "Missing translations"; then
  MISSING_COUNT=$(echo "$MISSING_OUTPUT" | grep -c '^ ' || true)
  warn "Found $MISSING_COUNT missing translation key(s)"
  echo "$MISSING_OUTPUT" | head -60
  if [[ $MISSING_COUNT -gt 60 ]]; then
    echo "  ... (truncated, $MISSING_COUNT total)"
  fi
else
  ok "No missing translation keys detected"
fi

if $CHECK_ONLY; then
  echo ""
  echo "Done (--check-only). No files were modified."
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 2: Copy missing keys from en/ into target locales with "replace_me"
# ---------------------------------------------------------------------------
step "Step 2/4 — Syncing missing keys to target locales (placeholder: replace_me)"

LOCALE_ARG="$LOCALE" LOCALES_ROOT="$LOCALES_ROOT" \
ruby -ryaml -e '
  locales_root = ENV.fetch("LOCALES_ROOT")
  only_locale  = ENV.fetch("LOCALE_ARG", "").strip

  # Discover all locale folders (excluding en)
  all_locales = Dir.children(locales_root)
    .select { |d| File.directory?(File.join(locales_root, d)) }
    .reject { |d| d == "en" }
    .sort

  if !only_locale.empty?
    unless all_locales.include?(only_locale)
      abort("Locale \"#{only_locale}\" not found under #{locales_root}")
    end
    all_locales = [only_locale]
  end

  # --- helpers ---

  def load_tree(path)
    return {} unless File.exist?(path)
    data = YAML.load_file(path) || {}
    # Strip the root locale key: { "en" => { ... } } → { ... }
    data.is_a?(Hash) && data.size == 1 ? data.values.first : data
  end

  def dump_locale(locale, tree)
    YAML.dump({ locale => tree })
  end

  # Map an en filename to its target locale filename
  def target_filename(en_basename, locale)
    if en_basename == "en.yml"
      "#{locale}.yml"
    else
      en_basename.sub(/\.en\.yml\z/, ".#{locale}.yml")
    end
  end

  # Deep-merge: insert missing keys from src into dst with placeholder value.
  # Returns the number of keys inserted.
  def deep_sync!(src, dst, inserted_count = [0])
    case src
    when Hash
      src.each do |k, v|
        if dst.is_a?(Hash)
          if dst.key?(k)
            # Key exists — recurse if both are hashes
            if v.is_a?(Hash) && dst[k].is_a?(Hash)
              deep_sync!(v, dst[k], inserted_count)
            end
            # If key exists but types differ (e.g. src is Hash, dst is String),
            # leave dst alone to avoid breaking existing translations.
          else
            # Key missing — insert with placeholder(s)
            dst[k] = placeholder_tree(v)
            inserted_count[0] += leaf_count(v)
          end
        end
      end
    end
    inserted_count[0]
  end

  # Build a deep copy where every leaf value is "replace_me"
  def placeholder_tree(obj)
    case obj
    when Hash
      obj.transform_values { |v| placeholder_tree(v) }
    when Array
      obj.map { |v| placeholder_tree(v) }
    else
      "replace_me"
    end
  end

  def leaf_count(obj)
    case obj
    when Hash  then obj.values.sum { |v| leaf_count(v) }
    when Array then obj.sum { |v| leaf_count(v) }
    else 1
    end
  end

  # --- main ---

  en_dir = File.join(locales_root, "en")
  en_files = Dir.glob(File.join(en_dir, "*.yml")).sort

  total_inserted = 0

  all_locales.each do |locale|
    locale_dir = File.join(locales_root, locale)
    locale_inserted = 0

    en_files.each do |en_path|
      en_basename = File.basename(en_path)
      target_name = target_filename(en_basename, locale)
      target_path = File.join(locale_dir, target_name)

      en_tree = load_tree(en_path)
      target_tree = load_tree(target_path)

      # If target file does not exist at all, create it entirely from en with placeholders
      if target_tree.empty? && !en_tree.empty?
        target_tree = placeholder_tree(en_tree)
        count = leaf_count(en_tree)
      else
        count = deep_sync!(en_tree, target_tree)
      end

      if count > 0
        File.write(target_path, dump_locale(locale, target_tree))
        locale_inserted += count
      end
    end

    if locale_inserted > 0
      puts "  #{locale}: inserted #{locale_inserted} missing key(s) with \"replace_me\""
      total_inserted += locale_inserted
    else
      puts "  #{locale}: already in sync"
    end
  end

  puts ""
  if total_inserted > 0
    puts "  Total: #{total_inserted} key(s) synced across #{all_locales.size} locale(s)"
  else
    puts "  All locales are in sync with en — nothing to do"
  end
'

# ---------------------------------------------------------------------------
# Step 3: Normalize locale files
# ---------------------------------------------------------------------------
step "Step 3/4 — Normalizing locale files"

bundle exec i18n-tasks normalize 2>&1
NORM_CHECK=$(bundle exec i18n-tasks check-normalized 2>&1 || true)

if echo "$NORM_CHECK" | grep -qi "not normalized\|error"; then
  warn "Some files may not be fully normalized — review output above"
else
  ok "All locale files are normalized"
fi

if $SYNC_ONLY; then
  echo ""
  echo "Done (--sync-only). Missing keys synced and normalized. DeepL translation skipped."
  echo "Run without --sync-only to also translate replace_me strings via DeepL."
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 4: Translate all "replace_me" strings via DeepL
# ---------------------------------------------------------------------------
step "Step 4/4 — Translating replace_me strings via DeepL"

if [[ -n "$LOCALE" ]]; then
  DEEPL_ARGS+=("--locale" "$LOCALE")
fi

"$SCRIPT_DIR/deepl_localise.sh" "${DEEPL_ARGS[@]+"${DEEPL_ARGS[@]}"}"

ok "DeepL translation complete"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  i18n sync & translate complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "    1. Review changes:  git diff config/locales/"
echo "    2. Verify:          bundle exec i18n-tasks missing"
echo "    3. Commit:          git add config/locales/ && git commit -m 'i18n: sync missing keys and translate'"
echo ""
