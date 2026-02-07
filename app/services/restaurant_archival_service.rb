class RestaurantArchivalService
  def self.archive_async(restaurant_id:, archived_by_id: nil, reason: nil)
    if RestaurantArchiveJob.respond_to?(:perform_async)
      RestaurantArchiveJob.perform_async(restaurant_id, archived_by_id, reason)
    else
      RestaurantArchiveJob.perform_later(restaurant_id: restaurant_id, archived_by_id: archived_by_id, reason: reason)
    end
  end

  def self.restore_async(restaurant_id:, archived_by_id: nil, reason: nil)
    if RestaurantRestoreJob.respond_to?(:perform_async)
      RestaurantRestoreJob.perform_async(restaurant_id, archived_by_id, reason)
    else
      RestaurantRestoreJob.perform_later(restaurant_id: restaurant_id, archived_by_id: archived_by_id, reason: reason)
    end
  end

  def self.archive!(restaurant:, archived_by_id: nil, reason: nil, archived_at: Time.current)
    new(restaurant: restaurant, archived_by_id: archived_by_id, reason: reason, archived_at: archived_at).archive!
  end

  def self.restore!(restaurant:, archived_by_id: nil, reason: nil)
    new(restaurant: restaurant, archived_by_id: archived_by_id, reason: reason).restore!
  end

  def initialize(restaurant:, archived_by_id: nil, reason: nil, archived_at: Time.current)
    @restaurant = restaurant
    @archived_by_id = archived_by_id
    @reason = reason
    @archived_at = archived_at
  end

  def archive!
    return if @restaurant.archived == true

    Restaurant.on_primary do
      ActiveRecord::Base.transaction do
        update_record(@restaurant, archived: true, status: :archived, archived_at: @archived_at)

        archive_restaurant_menus!
        archive_owned_menus!
        archive_owned_restaurant_children!
      end
    end

    invalidate_caches
  end

  def restore!
    return unless @restaurant.archived == true

    Restaurant.on_primary do
      ActiveRecord::Base.transaction do
        update_record(@restaurant, archived: false, status: :active, archived_at: nil)

        restore_restaurant_menus!
        restore_owned_menus!
        restore_owned_restaurant_children!
      end
    end

    invalidate_caches
  end

  private

  def update_record(record, archived:, status: nil, archived_at: nil)
    attributes = { archived: archived }

    attributes[:status] = status if status && record.respond_to?(:status=)
    attributes[:archived_at] = archived_at if record.respond_to?(:archived_at=)
    attributes[:archived_reason] = @reason if record.respond_to?(:archived_reason=) && @reason.present?
    attributes[:archived_by_id] = @archived_by_id if record.respond_to?(:archived_by_id=) && @archived_by_id.present?

    if !archived
      attributes[:archived_reason] = nil if record.respond_to?(:archived_reason=)
      attributes[:archived_by_id] = nil if record.respond_to?(:archived_by_id=)
    end

    record.update!(attributes)
  end

  def bulk_update_relation(relation, archived:, status: nil, archived_at: nil)
    attrs = {}

    if relation.klass.column_names.include?('archived')
      attrs[:archived] = archived
    end

    if status && relation.klass.column_names.include?('status') && relation.klass.respond_to?(:statuses)
      mapped = relation.klass.statuses[status.to_s]
      attrs[:status] = mapped if mapped.present?
    end

    if relation.klass.column_names.include?('archived_at')
      attrs[:archived_at] = archived_at
    end

    if relation.klass.column_names.include?('archived_reason')
      attrs[:archived_reason] = archived ? @reason : nil
    end

    if relation.klass.column_names.include?('archived_by_id')
      attrs[:archived_by_id] = archived ? @archived_by_id : nil
    end

    return if attrs.empty?

    attrs[:updated_at] = Time.current if relation.klass.column_names.include?('updated_at')

    relation.update_all(attrs)
  end

  def archive_restaurant_menus!
    attrs = {
      status: RestaurantMenu.statuses[:archived],
      updated_at: Time.current,
    }

    attrs[:archived_at] = @archived_at if RestaurantMenu.column_names.include?('archived_at')
    attrs[:archived_reason] = @reason if RestaurantMenu.column_names.include?('archived_reason')
    attrs[:archived_by_id] = @archived_by_id if RestaurantMenu.column_names.include?('archived_by_id')

    RestaurantMenu.where(restaurant_id: @restaurant.id).update_all(attrs)
  end

  def restore_restaurant_menus!
    attrs = {
      status: RestaurantMenu.statuses[:active],
      updated_at: Time.current,
    }

    if RestaurantMenu.column_names.include?('archived_at')
      attrs[:archived_at] = nil
    end

    if RestaurantMenu.column_names.include?('archived_reason')
      attrs[:archived_reason] = nil
    end

    if RestaurantMenu.column_names.include?('archived_by_id')
      attrs[:archived_by_id] = nil
    end

    RestaurantMenu.where(restaurant_id: @restaurant.id).update_all(attrs)
  end

  def archive_owned_menus!
    menu_ids = Menu.where(restaurant_id: @restaurant.id).pluck(:id)
    return if menu_ids.empty?

    bulk_update_relation(Menu.where(id: menu_ids), archived: true, status: :archived, archived_at: @archived_at)

    menusection_ids = Menusection.where(menu_id: menu_ids).pluck(:id)
    bulk_update_relation(Menusection.where(id: menusection_ids), archived: true, status: :archived, archived_at: @archived_at) if menusection_ids.any?

    menuitem_ids = Menuitem.where(menusection_id: menusection_ids).pluck(:id)
    bulk_update_relation(Menuitem.where(id: menuitem_ids), archived: true, status: :archived, archived_at: @archived_at) if menuitem_ids.any?

    if menuitem_ids.any?
      bulk_update_relation(Inventory.where(menuitem_id: menuitem_ids), archived: true, status: :archived, archived_at: @archived_at)
    end

    bulk_update_relation(Menuavailability.where(menu_id: menu_ids), archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(Menulocale.where(menu_id: menu_ids), archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(Smartmenu.where(menu_id: menu_ids), archived: true, status: :archived, archived_at: @archived_at)
  end

  def restore_owned_menus!
    menu_ids = Menu.where(restaurant_id: @restaurant.id).pluck(:id)
    return if menu_ids.empty?

    bulk_update_relation(Menu.where(id: menu_ids), archived: false, status: :active, archived_at: nil)

    menusection_ids = Menusection.where(menu_id: menu_ids).pluck(:id)
    bulk_update_relation(Menusection.where(id: menusection_ids), archived: false, status: :active, archived_at: nil) if menusection_ids.any?

    menuitem_ids = Menuitem.where(menusection_id: menusection_ids).pluck(:id)
    bulk_update_relation(Menuitem.where(id: menuitem_ids), archived: false, status: :active, archived_at: nil) if menuitem_ids.any?

    if menuitem_ids.any?
      bulk_update_relation(Inventory.where(menuitem_id: menuitem_ids), archived: false, status: :active, archived_at: nil)
    end

    bulk_update_relation(Menuavailability.where(menu_id: menu_ids), archived: false, status: :active, archived_at: nil)
    bulk_update_relation(Menulocale.where(menu_id: menu_ids), archived: false, status: :active, archived_at: nil)
    bulk_update_relation(Smartmenu.where(menu_id: menu_ids), archived: false, status: :active, archived_at: nil)
  end

  def archive_owned_restaurant_children!
    bulk_update_relation(@restaurant.tablesettings, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.employees, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.taxes, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.tips, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.restaurantavailabilities, archived: true, status: nil, archived_at: @archived_at)
    bulk_update_relation(@restaurant.restaurantlocales, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.allergyns, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.sizes, archived: true, status: :archived, archived_at: @archived_at)
    bulk_update_relation(@restaurant.tracks, archived: true, status: :archived, archived_at: @archived_at)

    if defined?(AlcoholPolicy)
      policy = AlcoholPolicy.find_by(restaurant_id: @restaurant.id)
      update_record(policy, archived: true, archived_at: @archived_at) if policy && policy.respond_to?(:archived=)
    end
  end

  def restore_owned_restaurant_children!
    bulk_update_relation(@restaurant.tablesettings, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.employees, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.taxes, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.tips, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.restaurantavailabilities, archived: false, status: :open, archived_at: nil)
    bulk_update_relation(@restaurant.restaurantlocales, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.allergyns, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.sizes, archived: false, status: :active, archived_at: nil)
    bulk_update_relation(@restaurant.tracks, archived: false, status: :active, archived_at: nil)

    if defined?(AlcoholPolicy)
      policy = AlcoholPolicy.find_by(restaurant_id: @restaurant.id)
      update_record(policy, archived: false, archived_at: nil) if policy && policy.respond_to?(:archived=)
    end
  end

  def invalidate_caches
    AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)
    AdvancedCacheService.invalidate_user_caches(@restaurant.user_id)
  rescue StandardError
    nil
  end
end
