# frozen_string_literal: true

class HerokuAddonPlanCost < ApplicationRecord
  validates :addon_service, presence: true
  validates :plan_name, presence: true
  validates :cost_cents_per_month, numericality: { greater_than_or_equal_to: 0 }
  validates :addon_service, uniqueness: { scope: :plan_name, case_sensitive: false }

  scope :ordered, -> { order(:addon_service, :plan_name) }
  scope :for_service, ->(service) { where(addon_service: service) }

  def cost_euros
    cost_cents_per_month / 100.0
  end
end
