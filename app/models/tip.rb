class Tip < ApplicationRecord
  belongs_to :restaurant
  validates :percentage, :presence => true, :numericality => {:only_float => true}
end
