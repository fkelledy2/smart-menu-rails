class MenuVersionSnapshotService
  SCHEMA_VERSION = 1

  def self.snapshot_for(menu)
    raise ArgumentError, 'menu is required' unless menu

    menu = Menu.includes(:menuavailabilities, menusections: :menuitems).find(menu.id)

    {
      schema_version: SCHEMA_VERSION,
      menu: snapshot_menu(menu),
      menuavailabilities: snapshot_menuavailabilities(menu),
      menusections: snapshot_sections(menu),
    }
  end

  def self.snapshot_menu(menu)
    {
      id: menu.id,
      name: menu.name,
      description: menu.description,
      status: menu.status,
      sequence: menu.sequence,
      displayImages: menu.displayImages,
      allowOrdering: menu.allowOrdering,
      inventoryTracking: menu.inventoryTracking,
      archived: menu.archived,
      covercharge: menu.covercharge,
      voiceOrderingEnabled: menu.voiceOrderingEnabled,
    }
  end

  def self.snapshot_menuavailabilities(menu)
    Array(menu.menuavailabilities)
      .select { |ma| ma.archived != true && ma.status.to_s == 'active' }
      .sort_by { |ma| [ma.sequence.to_i, ma.dayofweek_before_type_cast.to_i, ma.starthour.to_i, ma.startmin.to_i, ma.id.to_i] }
      .map do |ma|
        {
          id: ma.id,
          dayofweek: ma.dayofweek,
          starthour: ma.starthour,
          startmin: ma.startmin,
          endhour: ma.endhour,
          endmin: ma.endmin,
          status: ma.status,
        }
      end
  end

  def self.snapshot_sections(menu)
    Array(menu.menusections)
      .select { |s| s.archived != true && s.status.to_s == 'active' }
      .sort_by { |s| [s.sequence.to_i, s.id.to_i] }
      .map { |s| snapshot_section(s) }
  end

  def self.snapshot_section(section)
    {
      id: section.id,
      name: section.name,
      description: section.description,
      status: section.status,
      sequence: section.sequence,
      archived: section.archived,
      restricted: section.restricted,
      fromhour: section.fromhour,
      frommin: section.frommin,
      tohour: section.tohour,
      tomin: section.tomin,
      tasting_menu: section.tasting_menu,
      tasting_price_cents: section.tasting_price_cents,
      tasting_currency: section.tasting_currency,
      price_per: section.price_per,
      min_party_size: section.min_party_size,
      max_party_size: section.max_party_size,
      includes_description: section.includes_description,
      allow_substitutions: section.allow_substitutions,
      allow_pairing: section.allow_pairing,
      pairing_price_cents: section.pairing_price_cents,
      pairing_currency: section.pairing_currency,
      menuitems: snapshot_items(section),
    }
  end

  def self.snapshot_items(section)
    Array(section.menuitems)
      .select { |item| item.archived != true && item.status.to_s == 'active' }
      .sort_by { |item| [item.sequence.to_i, item.id.to_i] }
      .map do |item|
        {
          id: item.id,
          name: item.name,
          description: item.description,
          status: item.status,
          sequence: item.sequence,
          calories: item.calories,
          price: item.price,
          preptime: item.preptime,
          archived: item.archived,
          itemtype: item.itemtype,
          hidden: item.hidden,
          tasting_carrier: item.tasting_carrier,
          tasting_optional: item.tasting_optional,
          tasting_supplement_cents: item.tasting_supplement_cents,
          tasting_supplement_currency: item.tasting_supplement_currency,
          course_order: item.course_order,
          abv: item.abv,
          alcohol_classification: item.alcohol_classification,
          alcohol_notes: item.alcohol_notes,
          sommelier_category: item.sommelier_category,
          sommelier_parsed_fields: item.sommelier_parsed_fields,
          sommelier_needs_review: item.sommelier_needs_review,
          image_prompt: item.image_prompt,
        }
      end
  end

  private_class_method :snapshot_menu
  private_class_method :snapshot_menuavailabilities
  private_class_method :snapshot_sections
  private_class_method :snapshot_section
  private_class_method :snapshot_items
end
