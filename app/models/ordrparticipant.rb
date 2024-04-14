class Ordrparticipant < ApplicationRecord
  belongs_to :employee, optional: true
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true

  has_many :ordrparticipant_allergyn_filters, dependent: :destroy
  has_many :allergyns, through: :ordrparticipant_allergyn_filters

  enum role: {
    customer: 0,
    staff: 1
  }

  validates :ordr, :presence => true
  validates :sessionid, :presence => true

end
