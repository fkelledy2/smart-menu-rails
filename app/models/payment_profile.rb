class PaymentProfile < ApplicationRecord
  belongs_to :restaurant

  enum :merchant_model, {
    restaurant_mor: 0,
    smartmenu_mor: 1,
  }

  enum :primary_provider, {
    stripe: 0,
  }

  validates :merchant_model, presence: true
  validates :primary_provider, presence: true
end
