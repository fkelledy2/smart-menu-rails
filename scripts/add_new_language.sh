#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/add_new_language.sh <ISO_CODE>

Example:
  scripts/add_new_language.sh IE

Behavior:
  - Creates config/locales/<locale>/
  - Copies the file set from config/locales/en/
  - Preserves all keys/structure, but sets every leaf value to "replace_me"
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -ne 1 ]]; then
  usage
  [[ $# -ne 1 ]] && exit 1
  exit 0
fi

ISO_RAW="$1"
if [[ ! "$ISO_RAW" =~ ^[A-Za-z]{2}$ ]]; then
  echo "Error: ISO_CODE must be exactly 2 letters (e.g. IE)" >&2
  exit 1
fi

# Normalize to lower-case locale code for folder + YAML root key.
LOCALE_CODE="$(printf '%s' "$ISO_RAW" | tr '[:upper:]' '[:lower:]')"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

EN_DIR="$PROJECT_ROOT/config/locales/en"
TARGET_DIR="$PROJECT_ROOT/config/locales/$LOCALE_CODE"

if [[ ! -d "$EN_DIR" ]]; then
  echo "Error: missing template folder: $EN_DIR" >&2
  exit 1
fi

if [[ -e "$TARGET_DIR" ]]; then
  echo "Error: target locale folder already exists: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

cleanup() {
  # If something fails mid-run, remove the partially created locale folder.
  if [[ -d "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"
  fi
}
trap cleanup ERR

EN_DIR="$EN_DIR" TARGET_DIR="$TARGET_DIR" LOCALE_CODE="$LOCALE_CODE" \
ruby -ryaml -e '
  en_dir = ENV.fetch("EN_DIR")
  target_dir = ENV.fetch("TARGET_DIR")
  locale = ENV.fetch("LOCALE_CODE")

  def deep_replace(obj)
    case obj
    when Hash
      obj.transform_values { |v| deep_replace(v) }
    when Array
      obj.map { |v| deep_replace(v) }
    else
      "replace_me"
    end
  end

  def load_tree(path)
    data = YAML.load_file(path) || {}
    if data.is_a?(Hash) && data.size == 1
      data.values.first
    else
      data
    end
  end

  def dump_locale(locale, tree)
    YAML.dump({ locale => tree })
  end

  Dir.glob(File.join(en_dir, "*.yml")).sort.each do |src|
    base = File.basename(src)

    dest_name = if base == "en.yml"
      "#{locale}.yml"
    else
      base.sub(/\.en\.yml\z/, ".#{locale}.yml")
    end

    template = load_tree(src)
    replaced = deep_replace(template)

    dest = File.join(target_dir, dest_name)
    File.write(dest, dump_locale(locale, replaced))
  end
'

LOCALE_CODE="$LOCALE_CODE" PROJECT_ROOT="$PROJECT_ROOT" \
ruby -e '
  locale = ENV.fetch("LOCALE_CODE")
  root = ENV.fetch("PROJECT_ROOT")
  sym = ":#{locale}"

  files = [
    File.join(root, "config", "application.rb"),
    File.join(root, "config", "initializers", "locale.rb"),
  ]

  files.each do |path|
    src = File.read(path)
    if src.include?(sym)
      next
    end

    updated = src.gsub(/(available_locales\s*=\s*\[[^\]]*)\]/m) do
      prefix = Regexp.last_match(1)
      if prefix.include?("[")
        "#{prefix}, #{sym}]"
      else
        Regexp.last_match(0)
      end
    end

    if updated == src
      abort("Error: could not find available_locales array in #{path}")
    end

    File.write(path, updated)
  end
'

trap - ERR

echo "Created locale folder: config/locales/$LOCALE_CODE"
ls -1 "$TARGET_DIR" | wc -l | awk '{print "Files created: "$1}'
