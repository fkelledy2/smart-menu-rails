class VoiceCommand < ApplicationRecord
  belongs_to :smartmenu
  has_one_attached :audio

  # Active Storage validations
  validates :audio, content_type: ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/webm', 'audio/ogg'],
                    size: { less_than: 10.megabytes, message: 'must be less than 10MB' }

  enum :status, {
    queued: 'queued',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
  }

  validates :session_id, presence: true
end
