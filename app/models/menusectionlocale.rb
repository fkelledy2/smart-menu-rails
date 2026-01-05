class Menusectionlocale < ApplicationRecord
  belongs_to :menusection

  after_commit :enqueue_menu_item_search_reindex, on: %i[create update destroy]

  def enqueue_menu_item_search_reindex
    menu_id = menusection&.menu_id
    return if menu_id.blank?

    v = ENV['SMART_MENU_VECTOR_SEARCH_ENABLED']
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
