class MenuVersionDiffService
  SECTION_KEYS = %w[
    name
    description
    sequence
    restricted
    fromhour
    frommin
    tohour
    tomin
    tasting_menu
    tasting_price_cents
    tasting_currency
    price_per
    min_party_size
    max_party_size
    includes_description
    allow_substitutions
    allow_pairing
    pairing_price_cents
    pairing_currency
  ].freeze

  ITEM_KEYS = %w[
    name
    description
    sequence
    calories
    price
    preptime
    itemtype
    hidden
    tasting_carrier
    tasting_optional
    tasting_supplement_cents
    tasting_supplement_currency
    course_order
    abv
    alcohol_classification
    alcohol_notes
    sommelier_category
    sommelier_parsed_fields
    sommelier_needs_review
    image_prompt
  ].freeze

  def self.diff(from_version:, to_version:)
    raise ArgumentError, 'from_version is required' unless from_version
    raise ArgumentError, 'to_version is required' unless to_version

    from_snapshot = deep_stringify_keys(from_version.snapshot_json || {})
    to_snapshot = deep_stringify_keys(to_version.snapshot_json || {})

    from_sections = Array(from_snapshot['menusections'])
    to_sections = Array(to_snapshot['menusections'])

    from_sections_by_id = from_sections.index_by { |s| s['id'].to_i }
    to_sections_by_id = to_sections.index_by { |s| s['id'].to_i }

    from_section_ids = from_sections_by_id.keys.sort
    to_section_ids = to_sections_by_id.keys.sort

    added_sections = (to_section_ids - from_section_ids).map { |id| summarize_section(to_sections_by_id[id]) }
    removed_sections = (from_section_ids - to_section_ids).map { |id| summarize_section(from_sections_by_id[id]) }

    changed_sections = (from_section_ids & to_section_ids).filter_map do |id|
      changes = diff_fields(from_sections_by_id[id], to_sections_by_id[id], SECTION_KEYS)
      next if changes.empty?

      { id: id, changes: changes }
    end

    from_items_by_id = flatten_items(from_sections)
    to_items_by_id = flatten_items(to_sections)

    from_item_ids = from_items_by_id.keys.sort
    to_item_ids = to_items_by_id.keys.sort

    added_items = (to_item_ids - from_item_ids).map { |id| summarize_item(to_items_by_id[id]) }
    removed_items = (from_item_ids - to_item_ids).map { |id| summarize_item(from_items_by_id[id]) }

    changed_items = (from_item_ids & to_item_ids).filter_map do |id|
      changes = diff_fields(from_items_by_id[id], to_items_by_id[id], ITEM_KEYS)
      next if changes.empty?

      { id: id, changes: changes }
    end

    {
      sections: {
        added: added_sections,
        removed: removed_sections,
        changed: changed_sections,
      },
      items: {
        added: added_items,
        removed: removed_items,
        changed: changed_items,
      },
    }
  end

  def self.flatten_items(sections)
    items = {}
    Array(sections).each do |section|
      Array(section['menuitems']).each do |item|
        items[item['id'].to_i] = item
      end
    end
    items
  end

  def self.diff_fields(from_hash, to_hash, keys)
    from_hash ||= {}
    to_hash ||= {}

    keys.filter_map do |k|
      from_val = from_hash[k]
      to_val = to_hash[k]
      next if from_val == to_val

      { field: k, from: from_val, to: to_val }
    end
  end

  def self.summarize_section(section)
    return {} unless section

    { id: section['id'].to_i, name: section['name'], sequence: section['sequence'] }
  end

  def self.summarize_item(item)
    return {} unless item

    { id: item['id'].to_i, name: item['name'], sequence: item['sequence'], price: item['price'] }
  end

  def self.deep_stringify_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(k, v), h|
        h[k.to_s] = deep_stringify_keys(v)
      end
    when Array
      obj.map { |e| deep_stringify_keys(e) }
    else
      obj
    end
  end

  private_class_method :flatten_items
  private_class_method :diff_fields
  private_class_method :summarize_section
  private_class_method :summarize_item
  private_class_method :deep_stringify_keys
end
