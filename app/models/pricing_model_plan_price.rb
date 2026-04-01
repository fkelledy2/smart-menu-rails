# frozen_string_literal: true

class PricingModelPlanPrice < ApplicationRecord
  INTERVALS = %w[month year].freeze
  CURRENCIES = %w[EUR USD].freeze

  belongs_to :pricing_model
  belongs_to :plan

  validates :interval, presence: true, inclusion: { in: INTERVALS }
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :pricing_model_id, uniqueness: { scope: %i[plan_id interval currency] }

  scope :for_interval, ->(interval) { where(interval: interval) }
  scope :for_currency, ->(currency) { where(currency: currency) }
  scope :monthly, -> { for_interval('month') }
  scope :annual, -> { for_interval('year') }
  scope :ordered, -> { joins(:plan).order('plans.key ASC') }

  def price_euros
    price_cents / 100.0
  end
end
