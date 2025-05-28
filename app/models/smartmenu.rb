class Smartmenu < ApplicationRecord
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :tablesetting, optional: true

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
          restaurant.name + ' - ' + menu.name
      else
          restaurant.name
      end
  end

  validates :slug, :presence => true
  validates :restaurant, :presence => false
end
