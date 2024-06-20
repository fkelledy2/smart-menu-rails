class Allergyn < ApplicationRecord

  belongs_to :restaurant

  has_many :menuitem_allergyn_mappings, dependent: :destroy
  has_many :menuitems, through: :menuitem_allergyn_mappings

  has_many :ordrparticipant_allergyn_filters, dependent: :destroy
  has_many :ordrparticipants, through: :ordrparticipant_allergyn_filters

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  validates :name, :presence => true
  validates :symbol, :presence => true

end
