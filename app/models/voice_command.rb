class VoiceCommand < ApplicationRecord
  belongs_to :smartmenu
  has_one_attached :audio

  enum :status, {
    queued: 'queued',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
  }

  validates :session_id, presence: true
end
