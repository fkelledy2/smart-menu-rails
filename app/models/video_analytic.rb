# frozen_string_literal: true

# Tracks engagement events for the embedded demo video on the homepage.
# Records are insert-only — never updated. No PII beyond IP address.
class VideoAnalytic < ApplicationRecord
  VALID_EVENT_TYPES = %w[play pause seeked ended completion_25 completion_50 completion_75 completion_100].freeze

  validates :video_id,   presence: true, length: { maximum: 255 }
  validates :event_type, presence: true, inclusion: { in: VALID_EVENT_TYPES }

  scope :for_video,       ->(vid) { where(video_id: vid) }
  scope :completions_75,  -> { where(event_type: 'completion_75') }
  scope :recent,          -> { order(created_at: :desc) }
end
