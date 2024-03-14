class Ordr < ApplicationRecord
  belongs_to :employee
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems

end
