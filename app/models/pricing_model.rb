# frozen_string_literal: true

class PricingModel < ApplicationRecord
  CURRENCIES = %w[EUR USD].freeze
  LEGACY_VERSION = 'legacy_v0'

  belongs_to :published_by_user, class_name: 'User', optional: true
  has_many :pricing_model_plan_prices, dependent: :destroy
  has_many :userplans, dependent: :nullify

  enum :status, { draft: 0, published: 1, retired: 2 }

  validates :version, presence: true, uniqueness: true
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :status, presence: true

  scope :ordered, -> { order(effective_from: :desc) }
  scope :publishable, -> { where(status: :draft) }

  def self.current
    published.order(effective_from: :desc).first
  end

  def self.legacy_sentinel
    find_by(version: LEGACY_VERSION)
  end

  def inputs
    inputs_json || {}
  end

  def outputs
    outputs_json || {}
  end

  def immutable?
    published? || retired?
  end

  def price_for(plan:, interval:, currency:)
    pricing_model_plan_prices.find_by(
      plan: plan,
      interval: interval,
      currency: currency,
    )
  end
end
