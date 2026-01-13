class ProductEnrichment < ApplicationRecord
  belongs_to :product

  validates :source, presence: true
end
