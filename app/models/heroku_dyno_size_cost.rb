# frozen_string_literal: true

class HerokuDynoSizeCost < ApplicationRecord
  validates :dyno_size, presence: true, uniqueness: { case_sensitive: false }
  validates :cost_cents_per_month, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:dyno_size) }

  def cost_euros
    cost_cents_per_month / 100.0
  end

  # Default seed data for known Heroku dyno sizes (2026 pricing)
  DEFAULTS = {
    'eco' => 500,
    'basic' => 700,
    'standard-1x' => 2500,
    'standard-2x' => 5000,
    'performance-m' => 25000,
    'performance-l' => 50000,
    'private-s' => 28600,
    'private-m' => 57200,
    'private-l' => 114_400,
  }.freeze
end
