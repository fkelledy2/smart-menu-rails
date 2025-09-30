/**
 * Centralized event system for component communication
 * Replaces scattered jQuery event handling with a clean pub/sub system
 */
export class EventBus {
  static listeners = new Map();
  static debugMode = false;

  /**
   * Emit an event with optional data
   */
  static emit(eventName, data = {}) {
    if (EventBus.debugMode) {
      console.log(`[EventBus] Emitting: ${eventName}`, data);
    }

    // Create and dispatch custom event
    const event = new CustomEvent(eventName, { 
      detail: data,
      bubbles: true,
      cancelable: true 
    });

    document.dispatchEvent(event);

    // Also trigger any direct listeners
    const directListeners = EventBus.listeners.get(eventName);
    if (directListeners) {
      directListeners.forEach(({ callback, options }) => {
        try {
          if (options.once) {
            EventBus.off(eventName, callback);
          }
          callback(event);
        } catch (error) {
          console.error(`[EventBus] Error in listener for ${eventName}:`, error);
        }
      });
    }

    return event;
  }

  /**
   * Listen for an event
   */
  static on(eventName, callback, options = {}) {
    if (typeof callback !== 'function') {
      console.error('[EventBus] Callback must be a function');
      return;
    }

    // Add to DOM event listeners
    document.addEventListener(eventName, callback, options);
    
    // Track for cleanup
    if (!EventBus.listeners.has(eventName)) {
      EventBus.listeners.set(eventName, []);
    }
    
    EventBus.listeners.get(eventName).push({ callback, options });

    if (EventBus.debugMode) {
      console.log(`[EventBus] Added listener for: ${eventName}`);
    }
  }

  /**
   * Listen for an event once
   */
  static once(eventName, callback, options = {}) {
    EventBus.on(eventName, callback, { ...options, once: true });
  }

  /**
   * Remove event listener
   */
  static off(eventName, callback) {
    // Remove from DOM
    document.removeEventListener(eventName, callback);
    
    // Remove from tracking
    const listeners = EventBus.listeners.get(eventName);
    if (listeners) {
      const index = listeners.findIndex(l => l.callback === callback);
      if (index > -1) {
        listeners.splice(index, 1);
        
        if (listeners.length === 0) {
          EventBus.listeners.delete(eventName);
        }
      }
    }

    if (EventBus.debugMode) {
      console.log(`[EventBus] Removed listener for: ${eventName}`);
    }
  }

  /**
   * Remove all listeners for an event
   */
  static offAll(eventName) {
    const listeners = EventBus.listeners.get(eventName);
    if (listeners) {
      listeners.forEach(({ callback }) => {
        document.removeEventListener(eventName, callback);
      });
      EventBus.listeners.delete(eventName);
    }

    if (EventBus.debugMode) {
      console.log(`[EventBus] Removed all listeners for: ${eventName}`);
    }
  }

  /**
   * Clean up all event listeners
   */
  static cleanup() {
    EventBus.listeners.forEach((listeners, eventName) => {
      listeners.forEach(({ callback }) => {
        document.removeEventListener(eventName, callback);
      });
    });
    EventBus.listeners.clear();

    if (EventBus.debugMode) {
      console.log('[EventBus] Cleaned up all listeners');
    }
  }

  /**
   * Get list of active event listeners
   */
  static getListeners(eventName = null) {
    if (eventName) {
      return EventBus.listeners.get(eventName) || [];
    }
    return Object.fromEntries(EventBus.listeners);
  }

  /**
   * Enable/disable debug mode
   */
  static setDebugMode(enabled) {
    EventBus.debugMode = enabled;
    console.log(`[EventBus] Debug mode ${enabled ? 'enabled' : 'disabled'}`);
  }

  /**
   * Namespace helper for creating namespaced events
   */
  static namespace(namespace) {
    return {
      emit: (eventName, data) => EventBus.emit(`${namespace}:${eventName}`, data),
      on: (eventName, callback, options) => EventBus.on(`${namespace}:${eventName}`, callback, options),
      once: (eventName, callback, options) => EventBus.once(`${namespace}:${eventName}`, callback, options),
      off: (eventName, callback) => EventBus.off(`${namespace}:${eventName}`, callback),
      offAll: (eventName) => EventBus.offAll(`${namespace}:${eventName}`)
    };
  }

  /**
   * Create a scoped event bus for a specific component or module
   */
  static createScope(scopeName) {
    const scope = EventBus.namespace(scopeName);
    
    // Add scope-specific cleanup
    scope.cleanup = () => {
      const scopePrefix = `${scopeName}:`;
      const eventsToClean = [];
      
      EventBus.listeners.forEach((listeners, eventName) => {
        if (eventName.startsWith(scopePrefix)) {
          eventsToClean.push(eventName);
        }
      });
      
      eventsToClean.forEach(eventName => {
        EventBus.offAll(eventName);
      });
    };

    return scope;
  }

  /**
   * Utility method to wait for an event
   */
  static waitFor(eventName, timeout = 5000) {
    return new Promise((resolve, reject) => {
      let timeoutId;
      
      const handler = (event) => {
        clearTimeout(timeoutId);
        EventBus.off(eventName, handler);
        resolve(event);
      };

      EventBus.once(eventName, handler);

      if (timeout > 0) {
        timeoutId = setTimeout(() => {
          EventBus.off(eventName, handler);
          reject(new Error(`Timeout waiting for event: ${eventName}`));
        }, timeout);
      }
    });
  }

  /**
   * Batch emit multiple events
   */
  static emitBatch(events) {
    const results = [];
    
    events.forEach(({ eventName, data }) => {
      results.push(EventBus.emit(eventName, data));
    });
    
    return results;
  }

  /**
   * Create an event chain that waits for multiple events
   */
  static waitForAll(eventNames, timeout = 10000) {
    const promises = eventNames.map(eventName => 
      EventBus.waitFor(eventName, timeout)
    );
    
    return Promise.all(promises);
  }

  /**
   * Create an event race that resolves when any of the events fire
   */
  static waitForAny(eventNames, timeout = 5000) {
    const promises = eventNames.map(eventName => 
      EventBus.waitFor(eventName, timeout)
    );
    
    return Promise.race(promises);
  }
}

// Common application events
export const AppEvents = {
  // Application lifecycle
  APP_READY: 'app:ready',
  APP_DESTROY: 'app:destroy',
  
  // Page lifecycle
  PAGE_LOAD: 'page:load',
  PAGE_UNLOAD: 'page:unload',
  PAGE_CHANGE: 'page:change',
  
  // Component lifecycle
  COMPONENT_INIT: 'component:init',
  COMPONENT_READY: 'component:ready',
  COMPONENT_DESTROY: 'component:destroy',
  
  // Form events
  FORM_SUBMIT: 'form:submit',
  FORM_VALIDATE: 'form:validate',
  FORM_ERROR: 'form:error',
  FORM_SUCCESS: 'form:success',
  FORM_AUTO_SAVE: 'form:auto-save',
  
  // Table events
  TABLE_INIT: 'table:init',
  TABLE_DATA_LOAD: 'table:data:load',
  TABLE_ROW_SELECT: 'table:row:select',
  TABLE_ROW_CLICK: 'table:row:click',
  TABLE_FILTER: 'table:filter',
  TABLE_SORT: 'table:sort',
  
  // Select events
  SELECT_INIT: 'select:init',
  SELECT_CHANGE: 'select:change',
  SELECT_CLEAR: 'select:clear',
  
  // Modal events
  MODAL_OPEN: 'modal:open',
  MODAL_CLOSE: 'modal:close',
  MODAL_CONFIRM: 'modal:confirm',
  
  // Notification events
  NOTIFY_SUCCESS: 'notify:success',
  NOTIFY_ERROR: 'notify:error',
  NOTIFY_WARNING: 'notify:warning',
  NOTIFY_INFO: 'notify:info',
  
  // Data events
  DATA_LOAD: 'data:load',
  DATA_SAVE: 'data:save',
  DATA_DELETE: 'data:delete',
  DATA_ERROR: 'data:error',
  
  // UI events
  UI_LOADING_START: 'ui:loading:start',
  UI_LOADING_END: 'ui:loading:end',
  UI_THEME_CHANGE: 'ui:theme:change',
  
  // Business events
  RESTAURANT_SELECT: 'restaurant:select',
  MENU_SELECT: 'menu:select',
  MENUSECTION_SELECT: 'menusection:select',
  MENUITEM_SELECT: 'menuitem:select',
  ORDER_CREATE: 'order:create',
  ORDER_UPDATE: 'order:update'
};

// Export a default instance for convenience
export default EventBus;
