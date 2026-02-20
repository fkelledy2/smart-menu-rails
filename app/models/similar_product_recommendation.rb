# frozen_string_literal: true

class SimilarProductRecommendation < ApplicationRecord
  belongs_to :product
  belongs_to :recommended_product, class_name: 'Product'

  validates :product_id, uniqueness: { scope: :recommended_product_id }

  scope :for_product, ->(product_id) { where(product_id: product_id).order(score: :desc) }
end
