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
    this.originalHandlers = {
      connected: null,
      disconnected: null,
      rejected: null
    };
    
    this.connect();
  }
  
  // Safe getter for monitor with fallback
  getMonitor() {
    return this.consumer?.connection?.monitor || null;
  }
  
  // Safe getter for events with fallback
  getEvents() {
    const monitor = this.getMonitor();
    if (!monitor) return null;
    if (!monitor.events) {
      monitor.events = {};
    }
    return monitor.events;
  }
  
  // Store original handlers safely
  storeOriginalHandlers() {
    const events = this.getEvents();
    if (!events) return false;
    
    // Store original handlers if they exist and are functions
    this.originalHandlers = {
      connected: typeof events.connected === 'function' ? events.connected : null,
      disconnected: typeof events.disconnected === 'function' ? events.disconnected : null,
      rejected: typeof events.rejected === 'function' ? events.rejected : null
    };
    
    return true;
  }
  
  // Setup our custom event handlers
  setupEventHandlers() {
    const events = this.getEvents();
    if (!events) return false;
    
    events.connected = () => {
      console.log('WebSocket connection established');
      this.isConnected = true;
      this.reconnectAttempts = 0;
      if (this.originalHandlers.connected) {
        this.originalHandlers.connected();
      }
    };
    
    events.disconnected = () => {
      console.log('WebSocket connection lost');
      this.isConnected = false;
      if (this.originalHandlers.disconnected) {
        this.originalHandlers.disconnected();
      }
      this.attemptReconnect();
    };
    
    events.rejected = () => {
      console.log('WebSocket connection rejected');
      if (this.originalHandlers.rejected) {
        this.originalHandlers.rejected();
      }
      this.attemptReconnect();
    };
    
    return true;
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
      
      // Setup connection monitoring
      this.setupConnectionMonitoring();
      
    } catch (error) {
      console.error('Error initializing ActionCable consumer:', error);
      this.attemptReconnect();
    }
    
    return this.consumer;
  }
  
  // Setup connection monitoring with retry logic
  setupConnectionMonitoring() {
    // Check if we have everything we need
    if (!this.consumer?.connection?.monitor) {
      console.log('Connection monitor not ready, will retry...');
      setTimeout(() => this.setupConnectionMonitoring(), 100);
      return;
    }
    
    // Store original handlers
    if (!this.storeOriginalHandlers()) {
      console.log('Could not store original handlers, will retry...');
      setTimeout(() => this.setupConnectionMonitoring(), 100);
      return;
    }
    
    // Setup our event handlers
    if (!this.setupEventHandlers()) {
      console.log('Could not setup event handlers, will retry...');
      setTimeout(() => this.setupConnectionMonitoring(), 100);
      return;
    }
    
    console.log('Connection monitoring initialized successfully');
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
