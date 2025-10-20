import consumer from "./consumer"

export default class PresenceChannel {
  constructor(callbacks = {}) {
    this.callbacks = callbacks
    this.subscription = null
  }
  
  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      {
        connected: () => {
          console.log("Connected to presence channel")
          if (this.callbacks.onConnected) this.callbacks.onConnected()
        },

        disconnected: () => {
          console.log("Disconnected from presence channel")
          if (this.callbacks.onDisconnected) this.callbacks.onDisconnected()
        },

        received: (data) => {
          if (this.callbacks.onPresenceChange) {
            this.callbacks.onPresenceChange(data)
          }
        }
      }
    )
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
  
  appear() {
    if (this.subscription) {
      this.subscription.perform('appear')
    }
  }
  
  away() {
    if (this.subscription) {
      this.subscription.perform('away')
    }
  }
}
