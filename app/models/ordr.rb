class Ordr < ApplicationRecord
  include AASM
  include IdentityCache unless include?(IdentityCache)

  aasm column: 'status' do
    state :opened, initial: true
    state :ordered, :preparing, :ready, :delivered, :billrequested, :paid, :closed

    event :order do
      transitions from: :opened, to: :ordered
    end

    event :start_preparing do
      transitions from: :ordered, to: :preparing
    end

    event :mark_ready do
      transitions from: :preparing, to: :ready
    end

    event :mark_delivered do
      transitions from: :ready, to: :delivered
    end

    event :requestbill do
      transitions from: %i[opened ordered preparing ready delivered], to: :billrequested
      after do
        enqueue_auto_pay_capture_if_armed
      end
    end

    event :paybill do
      transitions from: [:billrequested], to: :paid
    end

    event :close do
      transitions from: [:paid], to: :closed
    end
  end

  # Callbacks for real-time kitchen updates.
  # Must use after_*_commit so broadcasts only fire after the transaction commits.
  # Using after_create / after_update would fire inside the transaction and could
  # broadcast kitchen tickets for orders that are subsequently rolled back.
  after_create_commit :broadcast_new_order
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?
  after_update_commit :cascade_status_to_items, if: :saved_change_to_status?
  after_update_commit :clear_station_tickets_if_terminal, if: :saved_change_to_status?
  after_update_commit :broadcast_auto_pay_disarmed, if: :auto_pay_disarmed?

  # Floorplan dashboard real-time tile updates
  after_commit :broadcast_floorplan_tile_update, on: %i[create update]

  # Standard ActiveRecord associations
  belongs_to :employee, optional: true
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, -> { reorder(id: :asc) }, dependent: :destroy, counter_cache: :ordritems_count
  has_many :ordrparticipants, -> { reorder(id: :asc) }, dependent: :destroy, counter_cache: :ordrparticipants_count
  has_many :ordractions, -> { reorder(id: :asc) }, dependent: :destroy
  has_many :ordr_station_tickets, -> { reorder(id: :asc) }, dependent: :destroy
  has_one :ordr_split_plan, dependent: :destroy
  has_many :ordr_split_payments, dependent: :destroy
  has_many :ordr_split_item_assignments, through: :ordr_split_plan
  has_many :payment_attempts, dependent: :destroy
  has_many :payment_refunds, dependent: :destroy
  has_many :receipt_deliveries, dependent: :destroy
  has_many :ordrnotes, -> { reorder(created_at: :desc) }, dependent: :destroy
  has_many :active_ordrnotes, -> { active.reorder(priority: :desc, created_at: :desc) }, class_name: 'Ordrnote'
  has_many :kitchen_notes, -> { for_kitchen.active.reorder(priority: :desc, created_at: :desc) }, class_name: 'Ordrnote'
  has_many :urgent_notes, -> { where(priority: %i[high urgent]).active.reorder(created_at: :desc) }, class_name: 'Ordrnote'

  # Optimized associations to prevent N+1 queries
  has_many :ordered_items_with_details, lambda {
    where(status: 20).includes(menuitem: %i[genimage allergyns sizes])
  }, class_name: 'Ordritem'

  has_many :prepared_items_with_details, lambda {
    where(status: 22).includes(menuitem: %i[genimage allergyns sizes])
  }, class_name: 'Ordritem'

  has_many :delivered_items_with_details, lambda {
    where(status: 25).includes(menuitem: %i[genimage allergyns sizes])
  }, class_name: 'Ordritem'

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

  # Cache invalidation hooks - DISABLED in favor of background jobs
  # after_update :invalidate_order_caches
  # after_destroy :invalidate_order_caches

  # Scopes for optimized queries
  scope :with_complete_items, lambda {
    includes(
      :restaurant,
      :tablesetting,
      :menu,
      :employee,
      ordritems: [
        menuitem: %i[genimage allergyns sizes menuitemlocales],
      ],
    )
  }

  scope :for_restaurant_dashboard, lambda { |restaurant_id|
    where(restaurant_id: restaurant_id)
      .with_complete_items
      .order(created_at: :desc)
  }

  enum :status, {
    opened: 0,
    ordered: 20,
    preparing: 22,
    ready: 24,
    delivered: 25,
    billrequested: 30,
    paid: 35,
    closed: 40,
  }

  def clear_station_tickets_if_terminal
    return unless status.in?(%w[delivered billrequested paid closed])

    ordr_station_tickets.destroy_all
  end

  # Auto Pay helpers
  def auto_pay_armed?
    payment_on_file? && auto_pay_enabled?
  end

  def auto_pay_capturable?
    auto_pay_armed? && gross.to_f.positive? && auto_pay_status != 'succeeded'
  end

  def grossInCents
    (gross || 0) * 100
  end

  def orderedItems
    ordritems.where(status: 20).all
  end

  def orderedItemsCount
    if association(:ordritems).loaded?
      ordritems.count { |item| item.status.to_s == 'ordered' }
    else
      ordritems.where(status: 20).count
    end
  end

  def preparedItems
    ordritems.where(status: 22).all
  end

  def preparedItemsCount
    if association(:ordritems).loaded?
      ordritems.count { |item| item.status.to_s == 'preparing' }
    else
      ordritems.where(status: 22).count
    end
  end

  def totalItemsCount
    if association(:ordritems).loaded?
      ordritems.count { |item| %w[opened ordered preparing ready delivered].include?(item.status.to_s) }
    else
      ordritems.where(status: [0, 20, 22, 24, 25]).count
    end
  end

  def deliveredItems
    ordritems.where(status: 25).all
  end

  def deliveredItemsCount
    if association(:ordritems).loaded?
      ordritems.count { |item| item.status.to_s == 'delivered' }
    else
      ordritems.where(status: 25).count
    end
  end

  def ordrDate
    created_at.strftime('%d/%m/%Y')
  end

  def diners
    # Count unique sessionids using SQL COUNT(DISTINCT ...) to avoid DISTINCT + ORDER BY issues
    ordrparticipants.where(role: 0).count('DISTINCT sessionid')
  end

  def runningTotal
    ordritems.sum('ordritemprice * quantity')
  end

  def orderedCount
    if association(:ordritems).loaded?
      ordritems.count { |item| %w[ordered preparing ready delivered].include?(item.status.to_s) }
    elsif association(:ordractions).loaded?
      ordractions.filter_map(&:ordritem).count { |item| %w[ordered preparing ready delivered].include?(item.status.to_s) }
    else
      ordractions.joins(:ordritem).where(ordritems: { status: [20, 22, 24, 25] }).count
    end
  end

  def addedCount
    if association(:ordritems).loaded?
      ordritems.select { |item| item.status.to_s == 'opened' }.sum(&:quantity)
    elsif association(:ordractions).loaded?
      ordractions.filter_map(&:ordritem).select { |item| item.status.to_s == 'opened' }.sum(&:quantity)
    else
      ordritems.where(status: 0).sum(:quantity)
    end
  end

  # When auto_pay is armed and gross changes (totals recalculated), disable auto_pay
  # so the customer must re-confirm. Called from OrdrsController#update -> calculate_order_totals.
  def disarm_auto_pay_if_totals_changed!
    return unless auto_pay_enabled?
    return unless will_save_change_to_gross? || will_save_change_to_tip?

    self.auto_pay_enabled = false
    self.auto_pay_consent_at = nil
  end

  # Returns true when auto_pay_enabled transitions from true to false in this update.
  def auto_pay_disarmed?
    saved_change_to_auto_pay_enabled? && !auto_pay_enabled? && saved_changes['auto_pay_enabled'].first == true
  end

  private

  def enqueue_auto_pay_capture_if_armed
    return unless auto_pay_capturable?

    AutoPayCaptureJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.warn(
      "[Ordr#enqueue_auto_pay_capture_if_armed] Failed to enqueue for ordr=#{id}: #{e.class}: #{e.message}",
    )
  end

  def broadcast_auto_pay_disarmed
    ActionCable.server.broadcast(
      "ordr_#{id}_channel",
      { type: 'auto_pay_disarmed', ordr_id: id },
    )
  rescue StandardError => e
    Rails.logger.warn(
      "[Ordr#broadcast_auto_pay_disarmed] Failed for ordr=#{id}: #{e.class}: #{e.message}",
    )
  end

  def broadcast_floorplan_tile_update
    return unless tablesetting_id && restaurant_id

    FloorplanBroadcastService.broadcast_tile(
      tablesetting_id: tablesetting_id,
      restaurant_id: restaurant_id,
    )
  rescue StandardError => e
    Rails.logger.warn(
      "[Ordr#broadcast_floorplan_tile_update] Failed for ordr=#{id}: #{e.class}: #{e.message}",
    )
  end

  def broadcast_new_order
    # Only broadcast kitchen-relevant statuses
    return unless %w[ordered preparing ready].include?(status)

    KitchenBroadcastService.broadcast_new_order(self)
  end

  def broadcast_status_change
    old_status_value = saved_change_to_status[0]
    new_status_value = saved_change_to_status[1]

    # Convert to string for comparison (handles both integer and symbol values)
    old_status = Ordr.statuses.key(old_status_value) || old_status_value.to_s
    new_status = Ordr.statuses.key(new_status_value) || new_status_value.to_s

    # Only broadcast kitchen-relevant status changes (including delivered to remove from dashboard)
    return unless %w[ordered preparing ready delivered billrequested].include?(new_status)

    KitchenBroadcastService.broadcast_status_change(self, old_status, new_status)
  end

  def cascade_status_to_items
    # When order status changes, update all child ordritems to match.
    # Use a single SQL UPDATE rather than Ruby iteration to avoid N+1 queries.
    # Skip removed items — their status must not be overwritten.
    new_status_int = Ordritem.statuses[status]
    removed_value  = Ordritem.statuses['removed']
    return if new_status_int.nil?

    ordritems
      .where.not(status: [new_status_int, removed_value])
      .update_all(status: new_status_int)
  end

  def invalidate_order_caches
    AdvancedCacheService.invalidate_order_caches(id)
    AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
    AdvancedCacheService.invalidate_user_caches(restaurant.user_id) if restaurant.user_id
  end
end
