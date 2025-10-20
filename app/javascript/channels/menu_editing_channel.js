import consumer from "./consumer"

export default class MenuEditingChannel {
  constructor(menuId, callbacks = {}) {
    this.menuId = menuId
    this.callbacks = callbacks
    this.subscription = null
  }
  
  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "MenuEditingChannel", menu_id: this.menuId },
      {
        connected: () => {
          console.log(`Connected to menu editing channel for menu ${this.menuId}`)
          if (this.callbacks.onConnected) this.callbacks.onConnected()
        },

        disconnected: () => {
          console.log("Disconnected from menu editing channel")
          if (this.callbacks.onDisconnected) this.callbacks.onDisconnected()
        },

        received: (data) => {
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
      case 'menu_change':
        if (this.callbacks.onMenuChange) this.callbacks.onMenuChange(data)
        break
      case 'field_locked':
        if (this.callbacks.onFieldLocked) this.callbacks.onFieldLocked(data)
        break
      case 'field_unlocked':
        if (this.callbacks.onFieldUnlocked) this.callbacks.onFieldUnlocked(data)
        break
    }
  }
  
  lockField(fieldName) {
    if (this.subscription) {
      this.subscription.send({
        action: 'lock_field',
        field: fieldName
      })
    }
  }
  
  unlockField(fieldName) {
    if (this.subscription) {
      this.subscription.send({
        action: 'unlock_field',
        field: fieldName
      })
    }
  }
  
  updateField(fieldName, value) {
    if (this.subscription) {
      this.subscription.send({
        action: 'update_field',
        field: fieldName,
        value: value
      })
    }
  }
}
