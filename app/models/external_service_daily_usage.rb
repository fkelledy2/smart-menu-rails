# frozen_string_literal: true

class ExternalServiceDailyUsage < ApplicationRecord
  SERVICES = %w[openai deepl google_vision stripe].freeze

  belongs_to :restaurant, optional: true

  validates :date, presence: true
  validates :service, presence: true, inclusion: { in: SERVICES }
  validates :dimension, presence: true
  validates :units, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_type, presence: true
  validates :service, uniqueness: { scope: %i[date dimension restaurant_id] }

  scope :for_service, ->(service) { where(service: service) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_month, ->(month) { where(date: month.all_month) }
  scope :global, -> { where(restaurant_id: nil) }
  scope :per_restaurant, -> { where.not(restaurant_id: nil) }
  scope :recent, -> { order(date: :desc) }

  def self.upsert_usage(date:, service:, dimension:, units:, unit_type: 'count', restaurant_id: nil, metadata: {})
    upsert( # rubocop:disable Rails/SkipsModelValidations
      {
        date: date,
        service: service,
        dimension: dimension,
        units: units,
        unit_type: unit_type,
        restaurant_id: restaurant_id,
        metadata: metadata,
        created_at: Time.current,
        updated_at: Time.current,
      },
      unique_by: :index_ext_svc_daily_usages_unique,
      update_only: %i[units metadata updated_at],
    )
  end
end
