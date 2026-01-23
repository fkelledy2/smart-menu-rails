class MenuVersionApplyService
  def self.apply_snapshot!(menu:, menu_version:)
    raise ArgumentError, 'menu is required' unless menu
    raise ArgumentError, 'menu_version is required' unless menu_version

    snapshot = menu_version.snapshot_json || {}
    snapshot = deep_stringify_keys(snapshot)

    apply_menu_attributes!(menu, snapshot['menu'] || {})
    apply_sections!(menu, Array(snapshot['menusections']))

    menu
  end

  def self.apply_menu_attributes!(menu, menu_hash)
    attrs = {}
    %w[name description status sequence displayImages allowOrdering inventoryTracking archived covercharge voiceOrderingEnabled].each do |k|
      next unless menu_hash.key?(k)
      attrs[k] = menu_hash[k]
    end

    menu.assign_attributes(attrs)
  rescue StandardError
    nil
  end

  def self.apply_sections!(menu, section_snapshots)
    return unless menu.association(:menusections).loaded?

    sections_by_id = Array(menu.menusections).index_by { |s| s.id.to_i }

    ordered_sections = section_snapshots.filter_map do |ss|
      s = sections_by_id[ss['id'].to_i]
      next unless s
      apply_section_attributes!(s, ss)
      apply_items!(s, Array(ss['menuitems']))
      s
    end

    menu.association(:menusections).target = ordered_sections
  end

  def self.apply_section_attributes!(section, ss)
    attrs = {}
    %w[
      name description status sequence archived restricted fromhour frommin tohour tomin
      tasting_menu tasting_price_cents tasting_currency price_per min_party_size max_party_size
      includes_description allow_substitutions allow_pairing pairing_price_cents pairing_currency
    ].each do |k|
      next unless ss.key?(k)
      attrs[k] = ss[k]
    end

    section.assign_attributes(attrs)
  rescue StandardError
    nil
  end

  def self.apply_items!(section, item_snapshots)
    return unless section.association(:menuitems).loaded?

    items_by_id = Array(section.menuitems).index_by { |it| it.id.to_i }

    ordered_items = item_snapshots.filter_map do |is|
      it = items_by_id[is['id'].to_i]
      next unless it
      apply_item_attributes!(it, is)
      it
    end

    section.association(:menuitems).target = ordered_items
  end

  def self.apply_item_attributes!(item, is)
    attrs = {}
    %w[
      name description status sequence calories price preptime archived itemtype hidden
      tasting_carrier tasting_optional tasting_supplement_cents tasting_supplement_currency
      course_order abv alcohol_classification alcohol_notes sommelier_category sommelier_parsed_fields
      sommelier_needs_review image_prompt
    ].each do |k|
      next unless is.key?(k)
      attrs[k] = is[k]
    end

    item.assign_attributes(attrs)
  rescue StandardError
    nil
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

  private_class_method :apply_menu_attributes!
  private_class_method :apply_sections!
  private_class_method :apply_section_attributes!
  private_class_method :apply_items!
  private_class_method :apply_item_attributes!
  private_class_method :deep_stringify_keys
end
