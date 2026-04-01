# frozen_string_literal: true

class InfraCostSnapshot < ApplicationRecord
  PROVIDERS = %w[heroku].freeze
  ENVIRONMENTS = HerokuAppInventorySnapshot::ENVIRONMENTS

  belongs_to :created_by_user, class_name: 'User', optional: true
  belongs_to :updated_by_user, class_name: 'User', optional: true

  validates :month, presence: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :space_name, presence: true
  validates :environment, presence: true, inclusion: { in: ENVIRONMENTS }
  validates :estimated_monthly_cost_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :provider, uniqueness: { scope: %i[space_name environment month] }

  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
  scope :for_environment, ->(env) { where(environment: env) }
  scope :for_space, ->(space_name) { where(space_name: space_name) }
  scope :recent, -> { order(month: :desc) }

  def cost_euros
    estimated_monthly_cost_cents / 100.0
  end

  def formation_rollup
    formation_rollup_json || {}
  end

  def addons_rollup
    addons_rollup_json || {}
  end
end
