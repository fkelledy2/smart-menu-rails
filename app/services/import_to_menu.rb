class ImportToMenu
  def initialize(restaurant:, import:)
    @restaurant = restaurant
    @import = import
  end

  def call
    validate_import!(allow_existing_menu: false)
    menu = nil
    ActiveRecord::Base.transaction do
      menu = build_menu!
      ensure_restaurant_menu_attachment!(menu)
      build_sections_and_items!(menu)
      # Sync restaurant allergen list based on this import's confirmed items
      begin
        allergens = collect_allergens
        sync_allergyns!(@restaurant, allergens) # first publish; stats not surfaced
      rescue StandardError => e
        Rails.logger.warn("[ImportToMenu.call] allergen sync warning: #{e.class}: #{e.message}")
      end
      # Expire caches so fresh data is visible after redirect
      begin
        menu.expire_menusections if menu.respond_to?(:expire_menusections)
        menu.menusections.each { |ms| ms.expire_menuitems if ms.respond_to?(:expire_menuitems) }
      rescue StandardError => e
        Rails.logger.warn("[ImportToMenu.call] cache expire warning: #{e.class}: #{e.message}")
      end
      @import.update!(menu: menu)
    end

    begin
      if defined?(Menu::BeveragePipelineStartJob) && menu&.id.present?
        Menu::BeveragePipelineStartJob.perform_async(menu.id, @restaurant.id, 'ocr_first_publish')
      end
    rescue StandardError => e
      Rails.logger.warn("[ImportToMenu.call] Failed to enqueue beverage pipeline: #{e.class}: #{e.message}")
    end

    # Trigger localization after transaction commits
    # Note: Menu model has after_commit callback that also triggers this,
    # but we explicitly trigger here to ensure it happens for OCR imports
    begin
      MenuLocalizationJob.perform_async('menu', menu.id)
      Rails.logger.info("[ImportToMenu.call] Enqueued localization for menu ##{menu.id}")
    rescue StandardError => e
      Rails.logger.warn("[ImportToMenu.call] Failed to enqueue localization: #{e.class}: #{e.message}")
    end

    enqueue_menu_item_search_reindex(menu)

    menu
  end

  # Republish into an existing menu: upsert confirmed sections and items
  # - Updates existing sections/items by name match
  # - Creates new sections/items if missing
  # - Does not remove or archive anything not present in the import
  def upsert_into_menu(menu, sync: false)
    validate_import!(allow_existing_menu: true)
    stats = { sections_created: 0, sections_updated: 0, items_created: 0, items_updated: 0, sections_archived: 0,
              items_archived: 0, }
    ActiveRecord::Base.transaction do
      # Update menu attributes from the import (forced update semantics)
      menu.update!(
        name: safe_text(@import.name.presence || menu.name),
        description: default_menu_description,
        status: 'active',
      )

      confirmed_sections = @import.ocr_menu_sections.confirmed.ordered.includes(:ocr_menu_items)
      kept_menusection_ids = []
      kept_menuitem_ids = []
      confirmed_sections.each do |section|
        # Find or create section using strongest key first
        menusection = if section.respond_to?(:menusection_id) && section.menusection_id.present?
                        menu.menusections.where(id: section.menusection_id).first
                      end
        # If no direct link, try name + sequence match to avoid collapsing duplicates
        menusection ||= menu.menusections.where(name: safe_text(section.name), sequence: section.sequence).first
        # Fallback to name-only if still not found
        menusection ||= menu.menusections.where(name: safe_text(section.name)).first_or_initialize
        menusection.assign_attributes(
          name: safe_text(section.name),
          description: safe_text(section.respond_to?(:description) ? section.description : nil),
          sequence: section.sequence,
          status: 'active',
        )
        if menusection.new_record?
          menusection.save!
          stats[:sections_created] += 1
        elsif menusection.changed?
          menusection.save!
          stats[:sections_updated] += 1
        end
        kept_menusection_ids << menusection.id
        # Expire items cache for this section as we will (up)insert items next
        begin
          menusection.expire_menuitems if menusection.respond_to?(:expire_menuitems)
        rescue StandardError => e
          Rails.logger.warn("[ImportToMenu.upsert] menusection expire warning: #{e.class}: #{e.message}")
        end
        # Link back to OCR section via modern association
        section.update_column(:menusection_id, menusection.id) if section.respond_to?(:menusection_id)

        Array(section.ocr_menu_items).select(&:is_confirmed).sort_by(&:sequence).each do |item|
          # Find or create item using strongest key first
          menuitem = if item.respond_to?(:menuitem_id) && item.menuitem_id.present?
                       menusection.menuitems.where(id: item.menuitem_id).first
                     end
          # If no direct link, try name + sequence within this section
          menuitem ||= menusection.menuitems.where(name: safe_text(item.name), sequence: item.sequence).first
          # Fallback to name-only if still not found
          menuitem ||= menusection.menuitems.where(name: safe_text(item.name)).first_or_initialize
          menuitem.assign_attributes(
            name: safe_text(item.name),
            description: safe_text(item.description),
            price: safe_price(item.price),
            sequence: item.sequence,
            status: 'active',
            itemtype: 'food',
            preptime: 0,
            calories: 0,
          )
          apply_alcohol_detection!(menuitem, section_name: section.name, item_name: item.name, item_description: item.description, overrides: (item.respond_to?(:metadata) ? item.metadata : nil))
          if menuitem.new_record?
            menuitem.save!
            stats[:items_created] += 1
          elsif menuitem.changed?
            menuitem.save!
            stats[:items_updated] += 1
          end
          kept_menuitem_ids << menuitem.id
          # Link allergyns for this item based on OCR allergens
          begin
            map_item_allergyns!(menuitem, Array(item.allergens), @restaurant)
          rescue StandardError => e
            Rails.logger.warn("[ImportToMenu.upsert] allergen map warning for menuitem ##{menuitem.id}: #{e.class}: #{e.message}")
          end
          # Link back to OCR item via modern association
          item.update_column(:menuitem_id, menuitem.id) if item.respond_to?(:menuitem_id)
        end
      end

      # Sync mode: archive sections/items not present in confirmed import
      if sync
        # Archive menu items not kept (across all sections in this menu)
        menu.menuitems.where.not(id: kept_menuitem_ids).find_each do |mi|
          next if mi.archived?

          mi.update!(status: 'archived')
          stats[:items_archived] += 1
        end

        # Archive sections not kept (and cascade does not remove items, they are already archived above)
        menu.menusections.where.not(id: kept_menusection_ids).find_each do |ms|
          next if ms.archived?

          ms.update!(status: 'archived')
          stats[:sections_archived] += 1
        end
      end
      # Always sync restaurant allergen list based on this import's confirmed items
      begin
        allergens = collect_allergens
        allergen_stats = sync_allergyns!(@restaurant, allergens)
        stats[:allergyns_created] = allergen_stats[:created]
        stats[:allergyns_activated] = allergen_stats[:activated]
        stats[:allergyns_updated]  = allergen_stats[:updated]
        stats[:allergyns_archived] = allergen_stats[:archived]
      rescue StandardError => e
        Rails.logger.warn("[ImportToMenu.upsert] allergen sync warning: #{e.class}: #{e.message}")
      end
      # Expire top-level menusections cache so additions are visible
      begin
        menu.expire_menusections if menu.respond_to?(:expire_menusections)
      rescue StandardError => e
        Rails.logger.warn("[ImportToMenu.upsert] menu expire warning: #{e.class}: #{e.message}")
      end
    end

    begin
      if defined?(Menu::BeveragePipelineStartJob) && menu&.id.present?
        Menu::BeveragePipelineStartJob.perform_async(menu.id, @restaurant.id, 'ocr_republish')
      end
    rescue StandardError => e
      Rails.logger.warn("[ImportToMenu.upsert] Failed to enqueue beverage pipeline: #{e.class}: #{e.message}")
    end

    # Re-localize updated menu to all locales to reflect changes
    begin
      MenuLocalizationJob.perform_async('menu', menu.id)
      Rails.logger.info("[ImportToMenu.upsert] Enqueued re-localization for menu ##{menu.id}")
    rescue StandardError => e
      Rails.logger.warn("[ImportToMenu.upsert] Failed to enqueue localization: #{e.class}: #{e.message}")
    end

    enqueue_menu_item_search_reindex(menu)

    [menu, stats]
  end

  private

  def enqueue_menu_item_search_reindex(menu)
    return unless menu&.id.present?

    v = ENV['SMART_MENU_VECTOR_SEARCH_ENABLED']
    vector_enabled = if v.nil? || v.to_s.strip == ''
                       true
                     else
                       v.to_s.downcase == 'true'
                     end
    return unless vector_enabled
    return if ENV['SMART_MENU_ML_URL'].to_s.strip == ''

    MenuItemSearchIndexJob.perform_async(menu.id)
  rescue StandardError => e
    Rails.logger.warn("[ImportToMenu] Failed to enqueue menu item search reindex: #{e.class}: #{e.message}")
    nil
  end

  def validate_import!(allow_existing_menu: false)
    raise StandardError, 'Menu already created for this import' if @import.menu_id.present? && !allow_existing_menu
    raise StandardError, 'Import is not completed' unless @import.completed?

    unless @import.ocr_menu_sections.respond_to?(:confirmed) && @import.ocr_menu_sections.confirmed.any?
      raise StandardError,
            'No confirmed sections to import'
    end
  end

  def build_menu!
    @restaurant.menus.create!(
      name: safe_text(@import.name.presence || "Imported Menu ##{@import.id}"),
      description: default_menu_description,
      status: 'active',
    )
  end

  def ensure_restaurant_menu_attachment!(menu)
    return if menu.blank?

    rm = RestaurantMenu.find_or_initialize_by(restaurant: @restaurant, menu: menu)
    return if rm.persisted?

    rm.sequence ||= (@restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
    rm.status ||= :active
    rm.availability_override_enabled = false if rm.availability_override_enabled.nil?
    rm.availability_state ||= :available
    rm.save!

    ensure_smartmenus_for_restaurant_menu!(menu)
  end

  def ensure_smartmenus_for_restaurant_menu!(menu)
    Smartmenu.on_primary do
      if Smartmenu.where(restaurant_id: @restaurant.id, menu_id: menu.id, tablesetting_id: nil).first.nil?
        Smartmenu.create!(restaurant: @restaurant, menu: menu, tablesetting: nil, slug: SecureRandom.uuid)
      end

      @restaurant.tablesettings.order(:id).each do |tablesetting|
        next unless Smartmenu.where(restaurant_id: @restaurant.id, menu_id: menu.id, tablesetting_id: tablesetting.id).first.nil?

        Smartmenu.create!(restaurant: @restaurant, menu: menu, tablesetting: tablesetting, slug: SecureRandom.uuid)
      end
    end
  rescue StandardError
    nil
  end

  def build_sections_and_items!(menu)
    @import
      .ocr_menu_sections
      .confirmed
      .ordered
      .includes(:ocr_menu_items)
      .find_each do |section|
        Rails.logger.info("[ImportToMenu.call] create section '#{safe_text(section.name)}' seq=#{section.sequence}")
        menusection = menu.menusections.create!(
          name: safe_text(section.name),
          description: safe_text(section.respond_to?(:description) ? section.description : nil),
          sequence: section.sequence,
          status: 'active',
        )
        # Link back to OCR section via modern association
        section.update_column(:menusection_id, menusection.id) if section.respond_to?(:menusection_id)

        Array(section.ocr_menu_items).select(&:is_confirmed).sort_by(&:sequence).each do |item|
          Rails.logger.info("[ImportToMenu.call]   create item '#{safe_text(item.name)}' seq=#{item.sequence} price=#{safe_price(item.price)}")
          menuitem = menusection.menuitems.create!(
            name: safe_text(item.name),
            description: safe_text(item.description),
            price: safe_price(item.price),
            sequence: item.sequence,
            status: 'active',
            itemtype: 'food',
            preptime: 0,
            calories: 0,
            # Dietary flags are not stored on Menuitem in current schema; omit mapping
          )
          apply_alcohol_detection!(menuitem, section_name: section.name, item_name: item.name, item_description: item.description)
          menuitem.save! if menuitem.changed?
          # Link allergyns for this item based on OCR allergens
          begin
            map_item_allergyns!(menuitem, Array(item.allergens), @restaurant)
          rescue StandardError => e
            Rails.logger.warn("[ImportToMenu.call] allergen map warning for menuitem ##{menuitem.id}: #{e.class}: #{e.message}")
          end
          # Link back to OCR item via modern association
          item.update_column(:menuitem_id, menuitem.id) if item.respond_to?(:menuitem_id)
        end
      end
  end

  def safe_text(str)
    str.to_s.strip
  end

  def safe_price(val)
    return 0.0 if val.nil? || val.to_s.strip == ''

    BigDecimal(val.to_s)
  rescue ArgumentError
    nil
  end

  def normalize_allergens(arr)
    Array(arr).map { |x| x.to_s.strip }.compact_blank.join(', ')
  end

  def default_menu_description
    "Imported from PDF on #{Time.current.strftime('%B %d, %Y')}"
  end

  # Detect alcohol attributes from OCR data and set on Menuitem.
  def apply_alcohol_detection!(menuitem, section_name:, item_name:, item_description:, overrides: nil)
    begin
      det = AlcoholDetectionService.detect(
        section_name: safe_text(section_name),
        item_name: safe_text(item_name),
        item_description: safe_text(item_description),
      )
      # Apply overrides from OCR metadata if provided
      if overrides.is_a?(Hash)
        ov = overrides.with_indifferent_access
        case ov[:alcohol_override].to_s
        when 'alcoholic'
          det = { decided: true, alcoholic: true, classification: ov[:alcohol_classification].presence || det[:classification], abv: ov[:alcohol_abv].presence || det[:abv], confidence: 1.0, note: 'override' }
        when 'non_alcoholic'
          det = { decided: true, alcoholic: false, classification: 'non_alcoholic', abv: ov[:alcohol_abv].presence || det[:abv], confidence: 1.0, note: 'override' }
        when 'undecided'
          # keep detection as-is
        end
      end

      # Log low-confidence or undecided for later ML analysis
      if det && (!det[:decided] || det[:confidence].to_f < 0.5)
        Rails.logger.info("[AlcoholDetection] low_confidence item='#{item_name}' section='#{section_name}' conf=#{det[:confidence]} decided=#{det[:decided]}")
      end

      return unless det && det[:decided]

      if det[:alcoholic]
        menuitem.alcohol_classification = det[:classification].presence || 'other'
        menuitem.abv = det[:abv] if det.key?(:abv)
      else
        menuitem.alcohol_classification = 'non_alcoholic'
        menuitem.abv = 0
      end
      if det[:note].present?
        notes = [menuitem.alcohol_notes.presence, det[:note]].compact.join(' ')
        menuitem.alcohol_notes = notes
      end
    rescue StandardError => e
      Rails.logger.warn("[ImportToMenu] alcohol detection failed for '#{item_name}': #{e.class}: #{e.message}")
    end
  end

  # Collect a unique, normalized set of allergen names from confirmed sections/items
  def collect_allergens
    names = []
    sections = @import.ocr_menu_sections
    sections = sections.confirmed if sections.respond_to?(:confirmed)
    sections.includes(:ocr_menu_items).find_each do |section|
      items = section.ocr_menu_items
      items = items.where(is_confirmed: true) if items.column_names.include?('is_confirmed')
      items.find_each do |item|
        next if item.allergens.blank?

        item.allergens.each do |a|
          next if a.blank?

          names << a.to_s.strip.downcase
        end
      end
    end
    names.uniq
  end

  # Ensure the restaurant's Allergyn records reflect the current list
  # - Create or activate/update allergens present in the import
  # - By default, do NOT archive allergens that are not present (non-destructive)
  # Returns stats: { created:, activated:, updated:, archived: }
  def sync_allergyns!(restaurant, allergen_names, archive_absent: false)
    # Normalize
    desired = allergen_names.map { |n| n.to_s.strip.downcase }.compact_blank.uniq
    existing = Allergyn.where(restaurant: restaurant).to_a
    stats = { created: 0, activated: 0, updated: 0, archived: 0 }

    # Activate or create present ones
    desired.each do |name|
      record = existing.find { |a| a.name.to_s.strip.downcase == name }
      if record
        if record.archived? || record.inactive?
          record.update!(status: 'active')
          stats[:activated] += 1
        end
        # Ensure names/symbols are consistent casing
        if record.name.to_s != name.titleize || record.symbol.to_s != generate_allergen_symbol(name)
          record.update!(name: name.titleize, symbol: generate_allergen_symbol(name))
          stats[:updated] += 1
        end
      else
        Allergyn.create!(
          restaurant: restaurant,
          name: name.titleize,
          symbol: generate_allergen_symbol(name),
          status: 'active',
        )
        stats[:created] += 1
      end
    end

    if archive_absent
      # Archive absent ones (optional, disabled by default)
      to_archive = existing.reject { |a| desired.include?(a.name.to_s.strip.downcase) }
      to_archive.each do |a|
        next if a.archived?

        a.update!(status: 'archived')
        stats[:archived] += 1
      end
    end

    stats
  end

  def generate_allergen_symbol(name)
    name.to_s.strip.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_]/, '').upcase
  end

  # For a given menuitem, ensure its MenuitemAllergynMapping set matches the provided allergen names
  def map_item_allergyns!(menuitem, allergen_names, restaurant)
    desired = Array(allergen_names).map { |n| n.to_s.strip.downcase }.compact_blank.uniq
    return if desired.empty?

    # Ensure Allergyns exist/are active for these names (leverages same normalization as restaurant sync)
    sync_allergyns!(restaurant, desired)

    # Lookup allergyn records
    allergyns = Allergyn.where(restaurant: restaurant).select { |a| desired.include?(a.name.to_s.strip.downcase) }

    # Compute current mappings
    current_ids = MenuitemAllergynMapping.where(menuitem_id: menuitem.id).pluck(:allergyn_id).to_set
    desired_ids = allergyns.to_set(&:id)

    # Create missing mappings
    (desired_ids - current_ids).each do |aid|
      MenuitemAllergynMapping.create!(menuitem_id: menuitem.id, allergyn_id: aid)
    end

    # Remove stale mappings (do not remove if allergen still present)
    (current_ids - desired_ids).each do |aid|
      MenuitemAllergynMapping.where(menuitem_id: menuitem.id, allergyn_id: aid).delete_all
    end
  end
end
