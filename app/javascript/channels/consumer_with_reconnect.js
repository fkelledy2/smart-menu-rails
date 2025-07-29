import { createConsumer } from "@rails/actioncable"

class ReconnectingConsumer {
  constructor() {
    this.consumer = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectInterval = 1000; // Start with 1 second
    this.maxReconnectInterval = 10000; // Max 10 seconds
    this.reconnectTimer = null;
    this.subscriptions = [];
    this.isConnected = false;
    this.connectionMonitor = null;
    
    this.connect();
  }
  
  connect() {
    try {
      this.consumer = createConsumer();
      
      // Store original subscription method
      const originalSubscribe = this.consumer.subscriptions.create.bind(this.consumer.subscriptions);
      const self = this;
      
      // Override subscription to track active subscriptions
      this.consumer.subscriptions.create = function(channelName, mixin) {
        const enhancedMixin = {
          ...mixin,
          connected: function() {
            this.isConnected = true;
            this.reconnectAttempts = 0;
            if (mixin.connected) {
              return mixin.connected.apply(this, arguments);
            }
          },
          disconnected: function() {
            this.isConnected = false;
            if (mixin.disconnected) {
              mixin.disconnected.apply(this, arguments);
            }
            if (self.attemptReconnect) {
              self.attemptReconnect();
            }
          },
          rejected: function() {
            if (mixin.rejected) {
              mixin.rejected.apply(this, arguments);
            }
            if (self.attemptReconnect) {
              self.attemptReconnect();
            }
          }
        };
        
        const subscription = originalSubscribe(channelName, enhancedMixin);
        
        // Store subscription with proper context
        self.subscriptions.push({ 
          channelName, 
          mixin: enhancedMixin, 
          subscription,
          context: self
        });
        
        return subscription;
      };
    } catch (error) {
      console.error('Error initializing ActionCable consumer:', error);
    }
    
    // Handle connection state changes
    const setupConnectionMonitoring = () => {
      if (!this.consumer || !this.consumer.connection || !this.consumer.connection.monitor) {
        console.log('Connection monitor not ready, retrying...');
        setTimeout(setupConnectionMonitoring, 100);
        return;
      }
      
      const monitor = this.consumer.connection.monitor;
      monitor.reconnectAttempts = 0;
      
      // Store original handlers to call them after our custom logic
      const originalConnected = monitor.events.connected;
      const originalDisconnected = monitor.events.disconnected;
      const originalRejected = monitor.events.rejected;
      
      monitor.events.connected = () => {
        console.log('WebSocket connection established');
        this.isConnected = true;
        this.reconnectAttempts = 0;
        if (originalConnected) originalConnected();
      };
      
      monitor.events.disconnected = () => {
        console.log('WebSocket connection lost');
        this.isConnected = false;
        if (originalDisconnected) originalDisconnected();
        this.attemptReconnect();
      };
      
      monitor.events.rejected = () => {
        console.log('WebSocket connection rejected');
        if (originalRejected) originalRejected();
        this.attemptReconnect();
      };
    };
    
    // Start monitoring with a small delay to ensure connection is ready
    setTimeout(setupConnectionMonitoring, 100);
    
    return this.consumer;
  }
  
  attemptReconnect() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error(`Max reconnection attempts (${this.maxReconnectAttempts}) reached. Giving up.`);
      return;
    }
    
    this.reconnectAttempts++;
    const delay = Math.min(
      this.reconnectInterval * Math.pow(2, this.reconnectAttempts - 1),
      this.maxReconnectInterval
    );
    
    console.log(`Attempting to reconnect in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
    
    this.reconnectTimer = setTimeout(() => {
      if (this.consumer) {
        this.consumer.disconnect();
      }
      this.connect();
      
      // Resubscribe to all channels
      this.subscriptions.forEach(({ channelName, mixin }) => {
        this.consumer.subscriptions.create(channelName, mixin);
      });
    }, delay);
  }
  
  getConsumer() {
    return this.consumer;
  }
}

// Create and export a singleton instance
export default new ReconnectingConsumer().getConsumer();
