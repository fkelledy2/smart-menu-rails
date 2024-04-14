class Ordritem < ApplicationRecord
  belongs_to :ordr
  belongs_to :menuitem
  has_one :ordrparticipant
end
