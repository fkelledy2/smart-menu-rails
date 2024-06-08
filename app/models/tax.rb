class Tax < ApplicationRecord
  belongs_to :restaurant
  enum taxtype: {
    local: 0,
    state: 1,
    federal: 2,
    service: 3
  }

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
  validates :taxpercentage, :presence => true, :numericality => {:only_float => true}
end
