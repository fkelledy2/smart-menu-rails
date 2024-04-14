class Tax < ApplicationRecord
  belongs_to :restaurant
  enum taxtype: {
    local: 0,
    state: 1,
    federal: 2,
    service: 3
  }
  validates :name, :presence => true
  validates :taxpercentage, :presence => true, :numericality => {:only_float => true}
end
