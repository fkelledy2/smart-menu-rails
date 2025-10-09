/**
 * Smart Restaurant ID Detection Utility
 * 
 * Provides intelligent restaurant context detection across the application
 * with multiple fallback strategies and caching for performance.
 */

class RestaurantContext {
  constructor() {
    this.cache = new Map();
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    this.observers = new Set();
    this.currentRestaurantId = null;
    
    // Initialize detection on construction
    this.detectRestaurantId();
    
    // Set up URL change detection for SPAs
    this.setupUrlChangeDetection();
  }

  /**
   * Get restaurant ID with smart detection and caching
   * @param {Element} context - Optional DOM context to search within
   * @returns {string|null} Restaurant ID or null if not found
   */
  getRestaurantId(context = document) {
    const cacheKey = this.getCacheKey(context);
    const cached = this.cache.get(cacheKey);
    
    // Return cached value if still valid
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.value;
    }
    
    // Detect restaurant ID using multiple strategies
    const restaurantId = this.detectRestaurantId(context);
    
    // Cache the result
    this.cache.set(cacheKey, {
      value: restaurantId,
      timestamp: Date.now()
    });
    
    // Notify observers if restaurant changed
    if (restaurantId !== this.currentRestaurantId) {
      this.currentRestaurantId = restaurantId;
      this.notifyObservers(restaurantId);
    }
    
    return restaurantId;
  }

  /**
   * Detect restaurant ID using multiple strategies
   * @param {Element} context - DOM context to search within
   * @returns {string|null} Restaurant ID or null if not found
   */
  detectRestaurantId(context = document) {
    // Strategy 1: URL path analysis (most reliable)
    const urlRestaurantId = this.getRestaurantIdFromUrl();
    if (urlRestaurantId) {
      return urlRestaurantId;
    }

    // Strategy 2: Context-specific data attributes
    const contextRestaurantId = this.getRestaurantIdFromContext(context);
    if (contextRestaurantId) {
      return contextRestaurantId;
    }

    // Strategy 3: Global DOM elements
    const globalRestaurantId = this.getRestaurantIdFromGlobalElements();
    if (globalRestaurantId) {
      return globalRestaurantId;
    }

    // Strategy 4: JavaScript global variables
    const jsGlobalRestaurantId = this.getRestaurantIdFromJsGlobals();
    if (jsGlobalRestaurantId) {
      return jsGlobalRestaurantId;
    }

    // Strategy 5: Meta tags
    const metaRestaurantId = this.getRestaurantIdFromMeta();
    if (metaRestaurantId) {
      return metaRestaurantId;
    }

    // Strategy 6: Local storage (for persistence)
    const storedRestaurantId = this.getRestaurantIdFromStorage();
    if (storedRestaurantId) {
      return storedRestaurantId;
    }

    return null;
  }

  /**
   * Extract restaurant ID from URL path
   * Supports multiple URL patterns:
   * - /restaurants/123
   * - /restaurants/123/menus/456
   * - /restaurants/123/edit
   */
  getRestaurantIdFromUrl() {
    const patterns = [
      /\/restaurants\/(\d+)/,           // Primary pattern
      /restaurant_id[=:](\d+)/,         // Query parameter pattern
      /\/r\/(\d+)/,                     // Short URL pattern
    ];

    const url = window.location.pathname + window.location.search;
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return null;
  }

  /**
   * Get restaurant ID from context-specific data attributes
   * @param {Element} context - DOM context to search within
   */
  getRestaurantIdFromContext(context) {
    const selectors = [
      '[data-restaurant-id]',
      '[data-bs-restaurant]',
      '[data-bs-restaurant_id]',
      '[data-restaurant]',
      '.restaurant-context[data-id]',
      '#restaurant-context[data-id]'
    ];

    for (const selector of selectors) {
      const element = context.querySelector(selector);
      if (element) {
        const restaurantId = element.dataset.restaurantId || 
                           element.dataset.bsRestaurant || 
                           element.dataset.bsRestaurantId ||
                           element.dataset.restaurant ||
                           element.dataset.id;
        if (restaurantId) {
          return restaurantId;
        }
      }
    }

    return null;
  }

  /**
   * Get restaurant ID from global DOM elements
   */
  getRestaurantIdFromGlobalElements() {
    const globalSelectors = [
      '#currentRestaurant',
      '#restaurant-id',
      '.current-restaurant-id',
      'body[data-restaurant-id]',
      'html[data-restaurant-id]'
    ];

    for (const selector of globalSelectors) {
      const element = document.querySelector(selector);
      if (element) {
        const restaurantId = element.textContent?.trim() || 
                           element.dataset.restaurantId ||
                           element.value;
        if (restaurantId) {
          return restaurantId;
        }
      }
    }

    return null;
  }

  /**
   * Get restaurant ID from JavaScript global variables
   */
  getRestaurantIdFromJsGlobals() {
    const globalVars = [
      'currentRestaurant',
      'restaurantContext',
      'appContext'
    ];

    for (const varName of globalVars) {
      const globalVar = window[varName];
      if (globalVar) {
        const restaurantId = globalVar.id || 
                           globalVar.restaurant_id || 
                           globalVar.restaurantId ||
                           (typeof globalVar === 'string' ? globalVar : null);
        if (restaurantId) {
          return restaurantId;
        }
      }
    }

    return null;
  }

  /**
   * Get restaurant ID from meta tags
   */
  getRestaurantIdFromMeta() {
    const metaSelectors = [
      'meta[name="restaurant-id"]',
      'meta[name="current-restaurant"]',
      'meta[property="restaurant:id"]'
    ];

    for (const selector of metaSelectors) {
      const meta = document.querySelector(selector);
      if (meta) {
        const restaurantId = meta.content || meta.getAttribute('content');
        if (restaurantId) {
          return restaurantId;
        }
      }
    }

    return null;
  }

  /**
   * Get restaurant ID from local storage
   */
  getRestaurantIdFromStorage() {
    try {
      const stored = localStorage.getItem('currentRestaurantId') ||
                    localStorage.getItem('restaurant_id') ||
                    sessionStorage.getItem('currentRestaurantId');
      return stored;
    } catch (error) {
      console.warn('Unable to access storage for restaurant ID:', error);
      return null;
    }
  }

  /**
   * Set restaurant ID in storage for persistence
   * @param {string} restaurantId - Restaurant ID to store
   */
  setRestaurantIdInStorage(restaurantId) {
    try {
      if (restaurantId) {
        localStorage.setItem('currentRestaurantId', restaurantId);
        sessionStorage.setItem('currentRestaurantId', restaurantId);
      } else {
        localStorage.removeItem('currentRestaurantId');
        sessionStorage.removeItem('currentRestaurantId');
      }
    } catch (error) {
      console.warn('Unable to store restaurant ID:', error);
    }
  }

  /**
   * Generate cache key for context-specific caching
   * @param {Element} context - DOM context
   */
  getCacheKey(context) {
    if (context === document) {
      return 'global';
    }
    return context.id || context.className || 'context';
  }

  /**
   * Set up URL change detection for single-page applications
   */
  setupUrlChangeDetection() {
    // Listen for popstate events (back/forward navigation)
    window.addEventListener('popstate', () => {
      this.clearCache();
      this.detectRestaurantId();
    });

    // Override pushState and replaceState to detect programmatic navigation
    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;

    history.pushState = (...args) => {
      originalPushState.apply(history, args);
      setTimeout(() => {
        this.clearCache();
        this.detectRestaurantId();
      }, 0);
    };

    history.replaceState = (...args) => {
      originalReplaceState.apply(history, args);
      setTimeout(() => {
        this.clearCache();
        this.detectRestaurantId();
      }, 0);
    };
  }

  /**
   * Add observer for restaurant ID changes
   * @param {Function} callback - Callback function to call when restaurant changes
   */
  addObserver(callback) {
    this.observers.add(callback);
  }

  /**
   * Remove observer
   * @param {Function} callback - Callback function to remove
   */
  removeObserver(callback) {
    this.observers.delete(callback);
  }

  /**
   * Notify all observers of restaurant ID change
   * @param {string|null} restaurantId - New restaurant ID
   */
  notifyObservers(restaurantId) {
    this.observers.forEach(callback => {
      try {
        callback(restaurantId);
      } catch (error) {
        console.error('Error in restaurant context observer:', error);
      }
    });
  }

  /**
   * Clear all cached restaurant IDs
   */
  clearCache() {
    this.cache.clear();
  }

  /**
   * Force refresh of restaurant context
   */
  refresh() {
    this.clearCache();
    return this.getRestaurantId();
  }

  /**
   * Get debug information about restaurant detection
   */
  getDebugInfo() {
    return {
      currentRestaurantId: this.currentRestaurantId,
      cacheSize: this.cache.size,
      observerCount: this.observers.size,
      detectionStrategies: {
        url: this.getRestaurantIdFromUrl(),
        globalElements: this.getRestaurantIdFromGlobalElements(),
        jsGlobals: this.getRestaurantIdFromJsGlobals(),
        meta: this.getRestaurantIdFromMeta(),
        storage: this.getRestaurantIdFromStorage()
      }
    };
  }
}

// Create singleton instance
const restaurantContext = new RestaurantContext();

// Export both the class and singleton instance
export { RestaurantContext, restaurantContext as default };

// Also make it available globally for legacy code
window.RestaurantContext = restaurantContext;
