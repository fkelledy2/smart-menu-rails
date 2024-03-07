class Tag < ApplicationRecord
  belongs_to :menuitem

  validates :name, :presence => true

end
