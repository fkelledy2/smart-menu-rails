class OrdrStationTicket < ApplicationRecord
  belongs_to :restaurant
  belongs_to :ordr

  has_many :ordritems, dependent: :nullify

  enum :station, {
    kitchen: 0,
    bar: 1,
  }

  enum :status, {
    ordered: 20,
    preparing: 22,
    ready: 24,
    collected: 26,
  }

  validates :station, presence: true
  validates :status, presence: true
  validates :sequence, presence: true

  validates :sequence, uniqueness: { scope: %i[ordr_id station] }

  after_commit :broadcast_new_ticket, on: :create
  after_commit :broadcast_status_change, on: :update

  private

  def broadcast_new_ticket
    OrdrStationTicketService.broadcast_ticket_event(self, event: 'new_ticket')
  end

  def broadcast_status_change
    return unless saved_change_to_status?

    old_status_value = saved_change_to_status[0]
    new_status_value = saved_change_to_status[1]

    old_status = OrdrStationTicket.statuses.key(old_status_value) || old_status_value.to_s
    new_status = OrdrStationTicket.statuses.key(new_status_value) || new_status_value.to_s

    OrdrStationTicketService.broadcast_ticket_event(
      self,
      event: 'status_change',
      old_status: old_status,
      new_status: new_status,
    )
  end
end
