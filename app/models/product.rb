class Product < ApplicationRecord
  has_many :menu_item_product_links, dependent: :destroy
  has_many :menuitems, through: :menu_item_product_links
  has_many :product_enrichments, dependent: :destroy

  validates :product_type, presence: true
  validates :canonical_name, presence: true

  validates :canonical_name, uniqueness: { scope: :product_type }
end
