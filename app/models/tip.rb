class Tip < ApplicationRecord
  belongs_to :restaurant

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  validates :percentage, :presence => true, :numericality => {:only_float => true}
end
