class Allergyn < ApplicationRecord
  belongs_to :menuitem

  validates :name, :presence => true
  validates :symbol, :presence => true
  validates :menuitem, :presence => true

end
