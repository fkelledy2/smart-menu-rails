# frozen_string_literal: true

class ExternalServiceMonthlyCost < ApplicationRecord
  SERVICES = %w[openai deepl google_vision stripe heroku other].freeze
  SOURCES = %w[manual api_ingest csv_import].freeze
  CURRENCIES = %w[EUR USD].freeze

  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :month, presence: true
  validates :service, presence: true, inclusion: { in: SERVICES }
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :service, uniqueness: { scope: %i[month currency] }

  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
  scope :for_service, ->(service) { where(service: service) }
  scope :for_currency, ->(currency) { where(currency: currency) }
  scope :manual, -> { where(source: 'manual') }
  scope :recent, -> { order(month: :desc) }

  def amount_euros
    amount_cents / 100.0
  end
end
