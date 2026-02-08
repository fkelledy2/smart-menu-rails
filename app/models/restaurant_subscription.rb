class RestaurantSubscription < ApplicationRecord
  belongs_to :restaurant

  enum :status, {
    inactive: 0,
    trialing: 1,
    active: 2,
    past_due: 3,
    canceled: 4,
  }

  validates :status, presence: true

  def active_or_trialing_with_payment_method?
    payment_method_on_file && %w[active trialing].include?(status.to_s)
  end
end
