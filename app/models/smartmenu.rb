class Smartmenu < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :tablesetting, optional: true

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :menu_id
  cache_index :tablesetting_id

  # Cache associations
  cache_belongs_to :restaurant
  cache_belongs_to :menu
  cache_belongs_to :tablesetting

  def menuName
    if menu
      menu.name
    else
      '*'
    end
  end

  def tableSettingName
    if tablesetting
      tablesetting.name
    else
      '*'
    end
  end

  def fqlinkname
    if menu && restaurant
      "#{menu.name} @ #{restaurant.name}"
    else
      restaurant.name
    end
  end

  validates :slug, presence: true
  validates :restaurant, presence: false
end
