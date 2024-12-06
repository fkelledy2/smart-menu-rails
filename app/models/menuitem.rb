class Menuitem < ApplicationRecord
  include ImageUploader::Attachment(:image)
  belongs_to :menusection

  has_many :menuitem_allergyn_mappings, dependent: :destroy
  has_many :allergyns, through: :menuitem_allergyn_mappings

  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :tags, through: :menuitem_tag_mappings

  has_many :menuitem_size_mappings, dependent: :destroy
  has_many :sizes, through: :menuitem_size_mappings

  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :ingredients, through: :menuitem_ingredient_mappings

  has_one :inventory, dependent: :destroy
  has_one :genimage, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :inventory, :presence => false
  validates :name, :presence => true
  validates :menusection, :presence => true
  validates :status, :presence => true
  validates :sequence, :presence => true
  validates :preptime, :presence => true, :numericality => {:only_integer => true}
  validates :price, :presence => true, :numericality => {:only_float => true}
  validates :calories, :presence => true, :numericality => {:only_integer => true}   
end
