# frozen_string_literal: true

class HerokuAppInventorySnapshot < ApplicationRecord
  ENVIRONMENTS = %w[production staging development ephemeral unknown].freeze

  validates :captured_at, presence: true
  validates :space_name, presence: true
  validates :app_id, presence: true
  validates :app_name, presence: true
  validates :environment, presence: true, inclusion: { in: ENVIRONMENTS }

  scope :for_space, ->(space_name) { where(space_name: space_name) }
  scope :captured_on, ->(date) { where(captured_at: date.all_day) }
  scope :recent, -> { order(captured_at: :desc) }
  scope :for_environment, ->(env) { where(environment: env) }
  scope :latest_per_app, lambda {
    from(
      select('DISTINCT ON (app_id) *').order(:app_id, captured_at: :desc),
      :heroku_app_inventory_snapshots,
    )
  }

  def formation
    formation_json || {}
  end

  def addons
    addons_json || {}
  end

  def production?
    environment == 'production'
  end

  def ephemeral?
    environment == 'ephemeral'
  end
end
