class Ordr < ApplicationRecord
  include AASM

  aasm :column => 'status' do
    state :opened, initial:true
    state :ordered, :billrequested, :paid, :closed

    event :order do
        status = :ordered
        transitions from: :opened, to: :ordered
    end

    event :requestbill do
        status = :billrequested
        transitions from: [:opened, :ordered], to: :billrequested
    end

    event :paybill do
        status = :billpaid
        transitions from: [:billrequested], to: :billpaid
    end

    event :close do
        status = :closed
        transitions from: [:billpaid], to: :closed
    end
  end

  belongs_to :employee, optional: true
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, dependent: :destroy
  has_many :ordrparticipants, dependent: :destroy
  has_many :ordractions, dependent: :destroy

  enum status: {
    opened: 0,
    ordered: 20,
    delivered: 25,
    billrequested: 30,
    closed: 40
  }

  def orderedItems
    ordritems.where(status: 20).all
  end

  def orderedItemsCount
    ordritems.where(status: 20).count
  end

  def preparedItems
    ordritems.where(status: 30).all
  end

  def preparedItemsCount
    ordritems.where(status: 30).count
  end

  def deliveredItems
    ordritems.where(status: 40).all
  end

  def deliveredItemsCount
    ordritems.where(status: 40).count
  end

  def ordrDate
      created_at.strftime("%d/%m/%Y")
  end

  def diners
    ordrparticipants.where(role: 0).distinct.pluck("sessionid").count
  end

  def runningTotal
    ordritems.pluck("ordritemprice").sum
  end

  validates :restaurant, :presence => true
  validates :menu, :presence => true
  validates :tablesetting, :presence => true

end
