class OrdritemEvent < ApplicationRecord
  belongs_to :ordritem
  belongs_to :restaurant

  validates :event_type, :occurred_at, presence: true
  validates :to_status, presence: true

  after_create_commit :enqueue_broadcast_job

  # Immutable — no updates or destroys
  before_update { throw :abort }
  before_destroy { throw :abort }

  private

  def enqueue_broadcast_job
    Ordritems::BroadcastStatusChangeJob.perform_later(id)
  end
end
