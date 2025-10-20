import consumer from "./consumer"

export default class KitchenChannel {
  constructor(restaurantId, callbacks = {}) {
    this.restaurantId = restaurantId
    this.callbacks = callbacks
    this.subscription = null
  }
  
  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "KitchenChannel", restaurant_id: this.restaurantId },
      {
        connected: () => {
          console.log(`Connected to kitchen channel for restaurant ${this.restaurantId}`)
          if (this.callbacks.onConnected) this.callbacks.onConnected()
        },

        disconnected: () => {
          console.log("Disconnected from kitchen channel")
          if (this.callbacks.onDisconnected) this.callbacks.onDisconnected()
        },

        received: (data) => {
          console.log("Kitchen update received:", data)
          this.handleMessage(data)
        }
      }
    )
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
  
  handleMessage(data) {
    switch(data.event) {
      case 'new_order':
        if (this.callbacks.onNewOrder) this.callbacks.onNewOrder(data.order)
        break
      case 'status_change':
        if (this.callbacks.onStatusChange) this.callbacks.onStatusChange(data)
        break
      case 'inventory_alert':
        if (this.callbacks.onInventoryAlert) this.callbacks.onInventoryAlert(data)
        break
      case 'staff_assignment':
        if (this.callbacks.onStaffAssignment) this.callbacks.onStaffAssignment(data)
        break
      case 'queue_update':
        if (this.callbacks.onQueueUpdate) this.callbacks.onQueueUpdate(data)
        break
      case 'metrics_update':
        if (this.callbacks.onMetricsUpdate) this.callbacks.onMetricsUpdate(data)
        break
    }
  }
  
  updateStatus(orderId, newStatus) {
    if (this.subscription) {
      this.subscription.send({
        action: 'update_status',
        order_id: orderId,
        new_status: newStatus
      })
    }
  }
  
  assignStaff(orderId, staffId) {
    if (this.subscription) {
      this.subscription.send({
        action: 'assign_staff',
        order_id: orderId,
        staff_id: staffId
      })
    }
  }
}
