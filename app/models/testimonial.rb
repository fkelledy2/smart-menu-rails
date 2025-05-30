class Testimonial < ApplicationRecord

  enum status: {
    unapproved: 0,
    approved: 1,
  }

  belongs_to :user
  belongs_to :restaurant

  validates :user, :presence => true
  validates :restaurant, :presence => true
end
