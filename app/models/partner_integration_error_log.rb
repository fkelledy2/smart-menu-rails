# frozen_string_literal: true

class PartnerIntegrationErrorLog < ApplicationRecord
  belongs_to :restaurant

  validates :adapter_type, presence: true
  validates :event_type, presence: true
  validates :error_message, presence: true
  validates :attempt_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }
  scope :for_adapter, ->(adapter_type) { where(adapter_type: adapter_type) }
end
