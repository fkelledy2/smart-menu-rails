class Ordritem < ApplicationRecord
  belongs_to :ordr
  belongs_to :menuitem
  has_one :ordrparticipant

  enum status: {
    ordered: 0,
    prepared: 10,
    delivered: 20,
  }

end
