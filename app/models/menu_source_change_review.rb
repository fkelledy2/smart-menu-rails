class MenuSourceChangeReview < ApplicationRecord
  enum :status, {
    pending: 0,
    resolved: 1,
    ignored: 2,
  }

  belongs_to :menu_source

  validates :status, presence: true
  validates :detected_at, presence: true
end
