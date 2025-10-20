class Ordr < ApplicationRecord
  include AASM
  include IdentityCache unless included_modules.include?(IdentityCache)

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
    end

    event :paybill do
      transitions from: [:billrequested], to: :paid
    end

    event :close do
      transitions from: [:paid], to: :closed
    end
  end

  # Callbacks for real-time kitchen updates
  after_create :broadcast_new_order
  after_update :broadcast_status_change, if: :saved_change_to_status?
  after_update :cascade_status_to_items, if: :saved_change_to_status?
  
  # Standard ActiveRecord associations
  belongs_to :employee, optional: true
  belongs_to :tablesetting
  belongs_to :menu
  belongs_to :restaurant

  has_many :ordritems, dependent: :destroy
  has_many :ordrparticipants, dependent: :destroy
  has_many :ordractions, dependent: :destroy

  # Optimized associations to prevent N+1 queries
  has_many :ordered_items_with_details, -> { 
    where(status: 20).includes(menuitem: [:genimage, :allergyns, :sizes]) 
  }, class_name: 'Ordritem'

  has_many :prepared_items_with_details, -> { 
    where(status: 22).includes(menuitem: [:genimage, :allergyns, :sizes]) 
  }, class_name: 'Ordritem'

  has_many :delivered_items_with_details, -> { 
    where(status: 25).includes(menuitem: [:genimage, :allergyns, :sizes]) 
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
  scope :with_complete_items, -> {
    includes(
      :restaurant,
      :tablesetting,
      :menu,
      :employee,
      ordritems: [
        menuitem: [:genimage, :allergyns, :sizes, :menuitemlocales]
      ]
    )
  }

  scope :for_restaurant_dashboard, ->(restaurant_id) {
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
    ordritems.where(status: 22).all
  end

  def preparedItemsCount
    ordritems.where(status: 22).count
  end

  def totalItemsCount
    ordritems.where(status: [0, 20, 22, 24, 25]).count
  end

  def deliveredItems
    ordritems.where(status: 25).all
  end

  def deliveredItemsCount
    ordritems.where(status: 25).count
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
    ordractions.joins(:ordritem).where(ordritems: { status: [20, 22, 24, 25] }).count
  end

  def addedCount
    ordractions.joins(:ordritem).where(ordritems: { status: 0 }).count
  end

  private

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
    # When order status changes, update all child ordritems to match
    # This ensures ordritems always reflect their parent order's status
    new_status_value = status
    
    ordritems.each do |item|
      # Only update if status is different to avoid unnecessary updates
      if item.status != new_status_value
        item.update_column(:status, Ordritem.statuses[new_status_value])
      end
    end
  end

  def invalidate_order_caches
    AdvancedCacheService.invalidate_order_caches(id)
    AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
    AdvancedCacheService.invalidate_user_caches(restaurant.user_id) if restaurant.user_id
  end
end
