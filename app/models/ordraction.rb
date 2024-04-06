class Ordraction < ApplicationRecord
  belongs_to :employee, optional: true
  belongs_to :ordrparticipant, optional: false
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true

  enum action: {
    participate: 0,
    openorder: 1,
    additem: 2,
    removeitem: 3,
    requestbill: 4,
    closeorder: 5,
  }

  validates :action, :presence => true
  validates :ordrparticipant, :presence => true
  validates :ordr, :presence => true
end
