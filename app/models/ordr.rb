class Ordr < ApplicationRecord
  include AASM
  include IdentityCache unless included_modules.include?(IdentityCache)

  aasm column: 'status' do
    state :opened, initial: true
    state :ordered, :billrequested, :paid, :closed

    event :order do
      transitions from: :opened, to: :ordered
    end

    event :requestbill do
      transitions from: %i[opened ordered], to: :billrequested
    end

    event :paybill do
      transitions from: [:billrequested], to: :billpaid
    end

    event :close do
      transitions from: [:billpaid], to: :closed
    end
  end

  # Standard ActiveRecord associations
  belongs_to :employee, optional: true
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, dependent: :destroy
  has_many :ordrparticipants, dependent: :destroy
  has_many :ordractions, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :tablesetting_id
  cache_index :menu_id
  cache_index :employee_id

  # Cache associations
  cache_belongs_to :restaurant
  cache_belongs_to :tablesetting
  cache_belongs_to :menu
  cache_belongs_to :employee
  cache_has_many :ordritems, embed: :ids
  cache_has_many :ordrparticipants, embed: :ids
  cache_has_many :ordractions, embed: :ids

  enum :status, {
    opened: 0,
    ordered: 20,
    delivered: 25,
    billrequested: 30,
    closed: 40,
  }

  def grossInCents
    gross * 100
  end

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

  def totalItemsCount
    ordritems.where(status: 0).count + ordritems.where(status: 20).count + ordritems.where(status: 30).count + ordritems.where(status: 40).count
  end

  def deliveredItems
    ordritems.where(status: 40).all
  end

  def deliveredItemsCount
    ordritems.where(status: 40).count
  end

  def ordrDate
    created_at.strftime('%d/%m/%Y')
  end

  def diners
    ordrparticipants.where(role: 0).distinct.pluck('sessionid').count
  end

  def runningTotal
    ordritems.pluck('ordritemprice').sum
  end

  def orderedCount
    ordractions.joins(:ordritem).where(ordritems: { status: 20 }).count
  end

  def addedCount
    ordractions.joins(:ordritem).where(ordritems: { status: 0 }).count
  end
end
