class Ordr < ApplicationRecord
  belongs_to :employee
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, dependent: :destroy
  has_many :ordrparticipants, dependent: :destroy

  enum status: {
    open: 0,
    billrequest: 1,
    close: 2
  }
  def diners
    ordrparticipants.where(role: 0).distinct.pluck("role", "sessionid").count
  end

  validates :restaurant, :presence => true
  validates :menu, :presence => true
  validates :tablesetting, :presence => true

end
