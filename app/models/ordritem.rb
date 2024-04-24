class Ordritem < ApplicationRecord
  belongs_to :ordr
  belongs_to :menuitem
  has_one :ordrparticipant

  enum status: {
    added: 0,
    removed: 10,
    ordered: 20,
    prepared: 30,
    delivered: 40,
  }

end
