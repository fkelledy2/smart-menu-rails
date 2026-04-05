# frozen_string_literal: true

# GuestRating records a star rating (1–5) left by a customer after checkout.
# Emits a `rating.low` domain event when stars <= 2.
# Source values: 'in_app' (default), 'google', 'tripadvisor' (future).
class GuestRating < ApplicationRecord
  SOURCES = %w[in_app google tripadvisor].freeze
  LOW_RATING_THRESHOLD = 2

  belongs_to :ordr
  belongs_to :restaurant

  validates :stars,  presence: true, inclusion: { in: 1..5 }
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :ordr_id, uniqueness: { scope: :source, message: 'already has a rating for this source' }

  scope :low_ratings, -> { where(stars: ..LOW_RATING_THRESHOLD) }
  scope :recent,      -> { order(created_at: :desc) }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }

  after_create_commit :emit_low_rating_event, if: :low_rating?

  def low_rating?
    stars <= LOW_RATING_THRESHOLD
  end

  private

  def emit_low_rating_event
    AgentDomainEvent.publish!(
      event_type: 'rating.low',
      source: self,
      payload: {
        'restaurant_id' => restaurant_id,
        'ordr_id' => ordr_id,
        'guest_rating_id' => id,
        'stars' => stars,
        'comment' => comment,
        'source' => source,
        'occurred_at' => created_at.iso8601,
      },
      idempotency_key: "rating.low:#{id}",
    )
  rescue StandardError => e
    Rails.logger.error("[GuestRating] Failed to emit rating.low event for rating #{id}: #{e.message}")
  end
end
