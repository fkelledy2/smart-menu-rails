class Product < ApplicationRecord
  has_many :menu_item_product_links, dependent: :destroy
  has_many :menuitems, through: :menu_item_product_links
  has_many :product_enrichments, dependent: :destroy
  has_one :flavor_profile, as: :profilable, dependent: :destroy
  has_many :similar_product_recommendations, dependent: :destroy
  has_many :similar_products, through: :similar_product_recommendations, source: :recommended_product

  validates :product_type, presence: true
  validates :canonical_name, presence: true

  validates :canonical_name, uniqueness: { scope: :product_type }
end
