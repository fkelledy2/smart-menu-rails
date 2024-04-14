class Inventory < ApplicationRecord
  belongs_to :menuitem

  validates :startinginventory, :presence => true, :numericality => {:only_integer => true}
  validates :currentinventory, :presence => true, :numericality => {:only_integer => true}
  validates :resethour, :presence => true, :numericality => {:only_integer => true}
end
