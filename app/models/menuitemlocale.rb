class Menuitemlocale < ApplicationRecord
  include IdentityCache

  belongs_to :menuitem

  after_commit :enqueue_menu_item_search_reindex, on: %i[create update destroy]

  # IdentityCache configuration
  cache_index :id
  cache_index :menuitem_id

  # Cache associations
  cache_belongs_to :menuitem

  def enqueue_menu_item_search_reindex
    menu_id = menuitem&.menusection&.menu_id
    return if menu_id.blank?

    v = ENV.fetch('SMART_MENU_VECTOR_SEARCH_ENABLED', nil)
    vector_enabled = if v.nil? || v.to_s.strip == ''
                       true
                     else
                       v.to_s.downcase == 'true'
                     end
    return unless vector_enabled
    return if ENV['SMART_MENU_ML_URL'].to_s.strip == ''

    MenuItemSearchIndexJob.perform_async(menu_id, locale)
  rescue StandardError
    nil
  end
end
