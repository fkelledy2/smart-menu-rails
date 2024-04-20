class Tablesetting < ApplicationRecord
  belongs_to :restaurant
  enum status: {
    free: 0,
    occupied: 1,
    archived: 2
  }

  enum tabletype: {
    indoor: 1,
    outdoor: 2
  }

  validates :tabletype, :presence => true
  validates :name, :presence => true
  validates :capacity, :presence => true, :numericality => {:only_integer => true}
  validates :status, :presence => true
  validates :restaurant, :presence => true

end
