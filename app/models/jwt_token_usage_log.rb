# frozen_string_literal: true

class JwtTokenUsageLog < ApplicationRecord
  self.record_timestamps = false

  belongs_to :jwt_token, class_name: 'AdminJwtToken',
                         inverse_of: :usage_logs

  validates :endpoint, presence: true
  validates :http_method, presence: true
  validates :response_status, presence: true, numericality: { only_integer: true }

  before_create { self.created_at ||= Time.current }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_token, ->(token_id) { where(jwt_token_id: token_id) }
  scope :since, ->(time) { where(created_at: time..) }
  # Logs older than 90 days are eligible for purge
  scope :purgeable, -> { where(created_at: ...90.days.ago) }
end
