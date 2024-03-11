class Tag < ApplicationRecord

  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_tag_mappings

  validates :name, :presence => true

end
