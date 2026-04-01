# frozen_string_literal: true

class StaffCostSnapshot < ApplicationRecord
  CURRENCIES = %w[EUR USD].freeze

  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :month, presence: true
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :support_cost_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :staff_cost_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :other_ops_cost_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :month, uniqueness: { scope: :currency }

  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
  scope :for_currency, ->(currency) { where(currency: currency) }
  scope :recent, -> { order(month: :desc) }

  def total_cost_cents
    support_cost_cents + staff_cost_cents + other_ops_cost_cents
  end

  def total_cost_euros
    total_cost_cents / 100.0
  end
end
