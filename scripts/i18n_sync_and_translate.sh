#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# i18n Sync & Translate
# =============================================================================
# A single script that covers all i18n maintenance tasks:
#
#   1. Check for missing translation keys (i18n-tasks missing)
#   2. Add missing keys to en/ by extracting default: values from source code
#   3. Copy missing keys from en/ into each locale with "replace_me" placeholder
#   4. Normalize locale files (i18n-tasks normalize)
#   5. Translate all "replace_me" strings via DeepL
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
step "Step 1/5 — Checking for missing translation keys"

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
# Step 2: Add missing keys to en/ with defaults extracted from source code
# ---------------------------------------------------------------------------
step "Step 2/5 — Adding missing keys to en locale files"

MISSING_TABLE="$MISSING_OUTPUT" LOCALES_ROOT="$LOCALES_ROOT" PROJECT_ROOT="$PROJECT_ROOT" \
ruby -ryaml <<'ADD_MISSING_EN_RUBY'
  require 'set'
  locales_root  = ENV.fetch("LOCALES_ROOT")
  project_root  = ENV.fetch("PROJECT_ROOT")
  missing_table = ENV.fetch("MISSING_TABLE", "")

  # --- Parse i18n-tasks missing table for "all" locale entries (missing from en) ---
  entries = []
  missing_table.each_line do |line|
    next unless line =~ /^\s*\|\s+(all|en)\s+\|\s+([\w.]+)\s+\|\s+(.+?)\s+\|/
    _locale, key, source_info = $1, $2, $3.strip
    source_path, line_num = nil, nil
    if source_info =~ /^([\w\/.\-_]+):(\d+)/
      source_path = $1
      line_num = $2.to_i
    end
    entries << { key: key, source_path: source_path, line_num: line_num }
  end

  if entries.empty?
    puts "  No keys missing from en — nothing to add"
    exit 0
  end

  # --- Helpers ---

  # Extract default: value from a source file line
  def extract_default(project_root, source_path, line_num)
    return nil unless source_path && line_num
    full_path = File.join(project_root, source_path)
    return nil unless File.exist?(full_path)
    lines = File.readlines(full_path)
    start_idx = [line_num - 1, 0].max
    end_idx   = [line_num + 2, lines.size - 1].min
    chunk = lines[start_idx..end_idx].join
    chunk =~ /default:\s*['"](.+?)['"]/ ? $1 : nil
  end

  def humanize_key(key)
    key.to_s.tr('_', ' ').sub(/\A\w/, &:upcase)
  end

  # --- Psych AST helpers for safe insertion ---

  # Find a child key-value pair in a Mapping node by key string
  def find_child(mapping, key_str)
    mapping.children.each_slice(2) do |k, v|
      return [k, v] if k.respond_to?(:value) && k.value == key_str
    end
    nil
  end

  # Find sorted insertion index for a new key in a Mapping
  def sorted_insert_idx(mapping, key_str)
    pairs = mapping.children.each_slice(2).to_a
    idx = pairs.index { |k, _| k.respond_to?(:value) && k.value.to_s > key_str }
    idx || pairs.size
  end

  # Insert a scalar key-value pair into a Mapping at sorted position
  def insert_scalar!(mapping, key_str, val_str)
    return false if find_child(mapping, key_str)
    key_node = Psych::Nodes::Scalar.new(key_str)
    val_node = Psych::Nodes::Scalar.new(val_str)
    pos = sorted_insert_idx(mapping, key_str)
    pairs = mapping.children.each_slice(2).to_a
    pairs.insert(pos, [key_node, val_node])
    mapping.children.replace(pairs.flatten(1))
    true
  end

  # Navigate/create a path of Mapping nodes, returning the deepest Mapping
  def ensure_mapping_path!(mapping, parts)
    current = mapping
    parts.each do |part|
      pair = find_child(current, part)
      if pair
        _, val = pair
        return nil unless val.is_a?(Psych::Nodes::Mapping)
        current = val
      else
        new_map = Psych::Nodes::Mapping.new
        key_node = Psych::Nodes::Scalar.new(part)
        pos = sorted_insert_idx(current, part)
        pairs = current.children.each_slice(2).to_a
        pairs.insert(pos, [key_node, new_map])
        current.children.replace(pairs.flatten(1))
        current = new_map
      end
    end
    current
  end

  # Get the root Mapping from a parsed YAML stream (stream > document > mapping)
  def root_mapping(ast)
    doc = ast.children.first
    return nil unless doc.is_a?(Psych::Nodes::Document)
    root = doc.root
    return nil unless root.is_a?(Psych::Nodes::Mapping)
    root
  end

  # Count depth of matching key path in an AST Mapping
  def matching_depth(mapping, key_parts)
    depth = 0
    current = mapping
    key_parts.each do |part|
      pair = find_child(current, part)
      break unless pair
      depth += 1
      _, val = pair
      break unless val.is_a?(Psych::Nodes::Mapping)
      current = val
    end
    depth
  end

  # --- Load all en YAML files as Psych ASTs ---
  en_asts = {}
  Dir.glob(File.join(locales_root, "en", "*.en.yml")).sort.each do |path|
    begin
      ast = Psych.parse_stream(File.read(path))
      rm = root_mapping(ast)
      next unless rm
      # The root mapping has one child: the locale key ("en") pointing to the content mapping
      pair = find_child(rm, "en")
      next unless pair
      _, content_mapping = pair
      next unless content_mapping.is_a?(Psych::Nodes::Mapping)
      en_asts[path] = { ast: ast, content: content_mapping }
    rescue Psych::SyntaxError
      next
    end
  end

  # --- Find which en file a key belongs to ---
  # Strategy: prefer files whose basename matches the first key segment (e.g.
  # "smartmenus.*" → smartmenus.en.yml), then fall back to deepest AST match.
  def find_target_file(key_parts, en_asts)
    prefix = key_parts.first

    # 1. Exact filename match: "smartmenus" → "smartmenus.en.yml"
    exact = en_asts.keys.find { |p| File.basename(p, ".en.yml") == prefix }
    return exact if exact

    # 2. Filename prefix match: "smartmenus" → "smartmenus_sections.en.yml" etc.
    # Pick the one with the deepest matching key path among prefix-matching files.
    prefix_matches = en_asts.select { |p, _| File.basename(p).start_with?(prefix) }
    unless prefix_matches.empty?
      best = prefix_matches.max_by { |_, info| matching_depth(info[:content], key_parts) }
      return best.first
    end

    # 3. Global fallback: deepest AST match across all files
    best_file, best_depth = nil, -1
    en_asts.each do |path, info|
      d = matching_depth(info[:content], key_parts)
      if d > best_depth
        best_depth = d
        best_file = path
      end
    end
    best_file
  end

  # --- Process each missing key ---
  added = 0
  modified_files = Set.new

  entries.each do |entry|
    key_parts = entry[:key].split('.')
    target_path = find_target_file(key_parts, en_asts)
    next unless target_path

    content = en_asts[target_path][:content]

    # Extract default from source, or humanize the last key segment
    default_val = extract_default(project_root, entry[:source_path], entry[:line_num])
    default_val ||= humanize_key(key_parts.last)

    # Navigate to parent mapping (creating intermediate mappings as needed)
    parent_parts = key_parts[0..-2]
    leaf_key = key_parts.last

    parent_mapping = parent_parts.empty? ? content : ensure_mapping_path!(content, parent_parts)
    next unless parent_mapping

    if insert_scalar!(parent_mapping, leaf_key, default_val)
      added += 1
      modified_files << target_path
    end
  end

  # Write modified files back (AST preserves all existing formatting)
  modified_files.each do |path|
    File.write(path, en_asts[path][:ast].to_yaml)
  end

  if added > 0
    puts "  Added #{added} missing key(s) to #{modified_files.size} en file(s)"
  else
    puts "  No keys to add"
  end
ADD_MISSING_EN_RUBY

# ---------------------------------------------------------------------------
# Step 3: Copy missing keys from en/ into target locales with "replace_me"
# ---------------------------------------------------------------------------
step "Step 3/5 — Syncing missing keys to target locales (placeholder: replace_me)"

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
    data = YAML.safe_load(File.read(path), permitted_classes: [Symbol, Date, Time]) || {}
    # Strip the root locale key: { "en" => { ... } } → { ... }
    data.is_a?(Hash) && data.size == 1 ? data.values.first : data
  rescue Psych::SyntaxError
    {} # skip unparseable files
  end

  def deep_sort(obj)
    case obj
    when Hash
      obj.sort_by { |k, _| k.to_s }.to_h.transform_values { |v| deep_sort(v) }
    when Array
      obj.map { |v| deep_sort(v) }
    else
      obj
    end
  end

  def dump_locale(locale, tree)
    YAML.dump({ locale => deep_sort(tree) })
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
# Step 4: Normalize ALL locale files (deep-sort keys, fix formatting)
# ---------------------------------------------------------------------------
step "Step 4/5 — Normalizing all resource bundles"

# 3a. Run i18n-tasks normalize for the main locale files it manages (non-fatal)
bundle exec i18n-tasks normalize 2>&1 || warn "i18n-tasks normalize encountered an error (non-fatal)"

# 3b. Normalize every YAML bundle by deep-sorting mapping keys.
#     Uses Psych AST manipulation to preserve all scalar styles (quotes, emoji,
#     booleans, numbers) — only key order is changed.
LOCALE_ARG="$LOCALE" LOCALES_ROOT="$LOCALES_ROOT" \
ruby -ryaml <<'NORMALIZE_RUBY'
  locales_root = ENV.fetch("LOCALES_ROOT")
  only_locale  = ENV.fetch("LOCALE_ARG", "").strip

  # Recursively sort mapping keys in a Psych AST node.
  # Mappings store children as [key1, val1, key2, val2, ...].
  def sort_mapping_keys!(node)
    case node
    when Psych::Nodes::Mapping
      pairs = node.children.each_slice(2).to_a
      sorted = pairs.sort_by { |key_node, _| key_node.respond_to?(:value) ? key_node.value : "" }
      was_sorted = pairs == sorted
      node.children.replace(sorted.flatten(1))
      sorted.each { |_, val_node| sort_mapping_keys!(val_node) }
      was_sorted && sorted.all? { |_, v| mapping_sorted?(v) }
    when Psych::Nodes::Sequence
      node.children.each { |child| sort_mapping_keys!(child) }
      true
    when Psych::Nodes::Document
      sort_mapping_keys!(node.root)
    when Psych::Nodes::Stream
      node.children.all? { |child| sort_mapping_keys!(child) }
    else
      true
    end
  end

  # Check if all mappings in a node are already sorted (without mutating).
  def mapping_sorted?(node)
    case node
    when Psych::Nodes::Mapping
      pairs = node.children.each_slice(2).to_a
      keys = pairs.map { |k, _| k.respond_to?(:value) ? k.value : "" }
      return false unless keys == keys.sort
      pairs.all? { |_, v| mapping_sorted?(v) }
    when Psych::Nodes::Sequence
      node.children.all? { |child| mapping_sorted?(child) }
    when Psych::Nodes::Document
      mapping_sorted?(node.root)
    when Psych::Nodes::Stream
      node.children.all? { |child| mapping_sorted?(child) }
    else
      true
    end
  end

  all_locales = Dir.children(locales_root)
    .select { |d| File.directory?(File.join(locales_root, d)) }
    .sort
  all_locales = all_locales & [only_locale] unless only_locale.empty?

  # Fix escaped Unicode sequences (\U0001FXXX) → real UTF-8 characters.
  # These appear in double-quoted YAML strings written by YAML.dump.
  UNICODE_ESCAPE_RE = /\\U([0-9A-Fa-f]{8})/

  files_normalised = 0
  skipped = []

  all_locales.each do |locale|
    Dir.glob(File.join(locales_root, locale, "*.yml")).sort.each do |path|
      raw = File.read(path)
      changed = false

      # Fix escaped emoji first (text-level, safe for any YAML)
      if raw.match?(UNICODE_ESCAPE_RE)
        raw = raw.gsub(UNICODE_ESCAPE_RE) { [$1.hex].pack("U") }
        changed = true
      end

      begin
        ast = Psych.parse_stream(raw)
      rescue Psych::SyntaxError
        # Write emoji fixes even if AST parsing fails
        if changed
          File.write(path, raw)
          files_normalised += 1
        else
          skipped << File.basename(path)
        end
        next
      end

      # Sort keys if not already sorted
      unless mapping_sorted?(ast)
        sort_mapping_keys!(ast)
        raw = ast.to_yaml
        changed = true
      end

      if changed
        File.write(path, raw)
        files_normalised += 1
      end
    end
  end

  if files_normalised > 0
    puts "  Normalised #{files_normalised} file(s)"
  else
    puts "  All resource bundles are already normalised"
  end
  puts "  Skipped #{skipped.uniq.size} unparseable file(s): #{skipped.uniq.join(', ')}" if skipped.any?
NORMALIZE_RUBY

# 3c. Verify normalisation
NORM_CHECK=$(bundle exec i18n-tasks check-normalized 2>&1 || true)

if echo "$NORM_CHECK" | grep -qi "not normalized\|requires normalization\|error"; then
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
step "Step 5/5 — Translating replace_me strings via DeepL"

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
