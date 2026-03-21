class MenuSourceChangeReview < ApplicationRecord
  enum :status, {
    pending: 0,
    resolved: 1,
    ignored: 2,
  }

  enum :diff_status, {
    diff_pending: 0,
    diff_complete: 1,
    diff_failed: 2,
  }, prefix: :diff

  belongs_to :menu_source

  validates :status, presence: true
  validates :detected_at, presence: true
end
