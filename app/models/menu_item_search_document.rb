class MenuItemSearchDocument < ApplicationRecord
  belongs_to :menu
  belongs_to :menuitem, class_name: 'Menuitem'

  validates :restaurant_id, :menu_id, :menuitem_id, :locale, :content_hash, presence: true
end
