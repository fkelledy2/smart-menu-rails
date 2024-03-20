class Ordr < ApplicationRecord
  belongs_to :employee
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, dependent: :destroy

  validates :restaurant, :presence => true
  validates :menu, :presence => true
  validates :tablesetting, :presence => true

end
