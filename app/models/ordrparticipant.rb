class Ordrparticipant < ApplicationRecord
  belongs_to :employee, optional: true
  belongs_to :ordr, optional: false
  belongs_to :ordritem, optional: true

  enum role: {
    customer: 0,
    staff: 1
  }

  validates :ordr, :presence => true
  validates :sessionid, :presence => true

end
