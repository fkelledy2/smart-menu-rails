class MenuItemProductLink < ApplicationRecord
  belongs_to :menuitem
  belongs_to :product

  validates :menuitem_id, uniqueness: { scope: :product_id }
end
