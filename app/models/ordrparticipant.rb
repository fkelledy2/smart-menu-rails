class Ordrparticipant < ApplicationRecord
  belongs_to :employee, optional: true
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

  enum role: {
    customer: 0,
    staff: 1
  }

  validates :ordr, :presence => true
  validates :sessionid, :presence => true
  validates :action, :presence => true

end
