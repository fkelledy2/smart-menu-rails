class Size < ApplicationRecord

  has_many :menuitem_size_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_size_mappings

  enum size: {
    xs: 0,
    sm: 1,
    md: 2,
    lg: 3,
    xl: 4,
  }

  validates :name, :presence => true
  validates :size, :presence => true

end
