/**
 * Smart Menu Service Worker
 * Provides offline functionality, caching, and background sync
 */

const CACHE_NAME = 'smart-menu-v1.0.0'
const STATIC_CACHE = 'smart-menu-static-v1.0.0'
const DYNAMIC_CACHE = 'smart-menu-dynamic-v1.0.0'
const API_CACHE = 'smart-menu-api-v1.0.0'

// Resources to cache immediately
const STATIC_RESOURCES = [
  '/',
  '/manifest.json',
  '/offline',
  '/icons/qr-logo.svg'
]

// Cache strategies for different request types
const CACHE_STRATEGIES = {
  static: 'cache-first',
  api: 'network-first',
  pages: 'stale-while-revalidate',
  images: 'cache-first'
}

class SmartMenuServiceWorker {
  constructor() {
    this.version = '1.0.0'
    this.caches = {
      static: STATIC_CACHE,
      dynamic: DYNAMIC_CACHE,
      api: API_CACHE
    }
    
    this.setupEventListeners()
  }

  setupEventListeners() {
    self.addEventListener('install', (event) => {
      console.log('[SW] Installing service worker version', this.version)
      event.waitUntil(this.install())
    })

    self.addEventListener('activate', (event) => {
      console.log('[SW] Activating service worker')
      event.waitUntil(this.activate())
    })

    self.addEventListener('fetch', (event) => {
      event.respondWith(this.handleFetch(event.request))
    })

    self.addEventListener('sync', (event) => {
      console.log('[SW] Background sync triggered:', event.tag)
      this.handleBackgroundSync(event)
    })

    self.addEventListener('push', (event) => {
      console.log('[SW] Push notification received')
      event.waitUntil(this.handlePushNotification(event))
    })

    self.addEventListener('notificationclick', (event) => {
      console.log('[SW] Notification clicked')
      this.handleNotificationClick(event)
    })
  }

  async install() {
    try {
      // Cache static resources
      const cache = await caches.open(this.caches.static)
      await cache.addAll(STATIC_RESOURCES)
      
      console.log('[SW] Static resources cached successfully')
      
      // Skip waiting to activate immediately
      self.skipWaiting()
    } catch (error) {
      console.error('[SW] Installation failed:', error)
    }
  }

  async activate() {
    try {
      // Clean up old caches
      const cacheNames = await caches.keys()
      const oldCaches = cacheNames.filter(name => 
        name.startsWith('smart-menu-') && !Object.values(this.caches).includes(name)
      )

      await Promise.all(
        oldCaches.map(cacheName => {
          console.log('[SW] Deleting old cache:', cacheName)
          return caches.delete(cacheName)
        })
      )

      // Take control of all clients
      self.clients.claim()
      
      console.log('[SW] Service worker activated successfully')
    } catch (error) {
      console.error('[SW] Activation failed:', error)
    }
  }

  async handleFetch(request) {
    try {
      // Determine cache strategy based on request
      if (request.url.includes('/api/')) {
        return this.networkFirstStrategy(request)
      } else if (request.destination === 'image') {
        return this.cacheFirstStrategy(request)
      } else if (request.mode === 'navigate') {
        return this.navigationStrategy(request)
      } else {
        return this.staleWhileRevalidateStrategy(request)
      }
    } catch (error) {
      console.error('[SW] Fetch handling failed:', error)
      return this.offlineFallback(request)
    }
  }

  async networkFirstStrategy(request) {
    try {
      // Try network first
      const response = await fetch(request)
      
      // Cache successful responses
      if (response.ok) {
        const cache = await caches.open(this.caches.api)
        cache.put(request, response.clone())
      }
      
      return response
    } catch (error) {
      // Fall back to cache
      const cachedResponse = await caches.match(request)
      if (cachedResponse) {
        return cachedResponse
      }
      
      return this.offlineFallback(request)
    }
  }

  async cacheFirstStrategy(request) {
    try {
      // Try cache first
      const cachedResponse = await caches.match(request)
      if (cachedResponse) {
        return cachedResponse
      }
      
      // Fall back to network
      const response = await fetch(request)
      
      if (response.ok) {
        const cache = await caches.open(this.caches.dynamic)
        cache.put(request, response.clone())
      }
      
      return response
    } catch (error) {
      return this.offlineFallback(request)
    }
  }

  async staleWhileRevalidateStrategy(request) {
    try {
      const cachedResponse = await caches.match(request)
      
      // Always try to update cache in background
      const fetchPromise = fetch(request).then(response => {
        if (response.ok) {
          const cache = caches.open(this.caches.dynamic)
          cache.then(c => c.put(request, response.clone()))
        }
        return response
      }).catch(() => null)
      
      // Return cached version immediately if available
      return cachedResponse || await fetchPromise || this.offlineFallback(request)
    } catch (error) {
      return this.offlineFallback(request)
    }
  }

  async navigationStrategy(request) {
    try {
      // Try network first for navigation
      const response = await fetch(request)
      return response
    } catch (error) {
      // Fall back to cached page or offline page
      const cachedResponse = await caches.match(request)
      if (cachedResponse) {
        return cachedResponse
      }
      
      // Return offline page
      return caches.match('/offline')
    }
  }

  async offlineFallback(request) {
    if (request.mode === 'navigate') {
      return caches.match('/offline')
    }
    
    // Return a basic offline response
    return new Response('Offline', {
      status: 503,
      statusText: 'Service Unavailable',
      headers: { 'Content-Type': 'text/plain' }
    })
  }

  handleBackgroundSync(event) {
    if (event.tag === 'order-sync') {
      event.waitUntil(this.syncOrders())
    } else if (event.tag === 'menu-sync') {
      event.waitUntil(this.syncMenuUpdates())
    } else if (event.tag === 'analytics-sync') {
      event.waitUntil(this.syncAnalytics())
    }
  }

  async syncOrders() {
    try {
      console.log('[SW] Syncing offline orders')
      
      // Get offline orders from IndexedDB
      const offlineOrders = await this.getOfflineOrders()
      
      for (const order of offlineOrders) {
        try {
          const response = await fetch('/api/orders', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify(order.data)
          })
          
          if (response.ok) {
            await this.removeOfflineOrder(order.id)
            console.log('[SW] Order synced successfully:', order.id)
          }
        } catch (error) {
          console.error('[SW] Failed to sync order:', order.id, error)
        }
      }
    } catch (error) {
      console.error('[SW] Order sync failed:', error)
    }
  }

  async syncMenuUpdates() {
    try {
      console.log('[SW] Syncing menu updates')
      
      // Implementation for syncing menu changes
      const menuUpdates = await this.getOfflineMenuUpdates()
      
      for (const update of menuUpdates) {
        try {
          const response = await fetch(`/api/menus/${update.menuId}`, {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify(update.data)
          })
          
          if (response.ok) {
            await this.removeOfflineMenuUpdate(update.id)
            console.log('[SW] Menu update synced:', update.id)
          }
        } catch (error) {
          console.error('[SW] Failed to sync menu update:', update.id, error)
        }
      }
    } catch (error) {
      console.error('[SW] Menu sync failed:', error)
    }
  }

  async syncAnalytics() {
    try {
      console.log('[SW] Syncing analytics data')
      
      // Sync offline analytics events
      const analyticsEvents = await this.getOfflineAnalytics()
      
      if (analyticsEvents.length > 0) {
        const response = await fetch('/api/analytics/batch', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: JSON.stringify({ events: analyticsEvents })
        })
        
        if (response.ok) {
          await this.clearOfflineAnalytics()
          console.log('[SW] Analytics synced successfully')
        }
      }
    } catch (error) {
      console.error('[SW] Analytics sync failed:', error)
    }
  }

  async handlePushNotification(event) {
    try {
      const data = event.data ? event.data.json() : {}
      
      const options = {
        body: data.body || 'New notification from Smart Menu',
        icon: '/icons/qr-logo.svg',
        badge: '/icons/qr-logo.svg',
        tag: data.tag || 'smart-menu-notification',
        data: data.data || {},
        actions: data.actions || [],
        requireInteraction: data.requireInteraction || false
      }
      
      return self.registration.showNotification(
        data.title || 'Smart Menu',
        options
      )
    } catch (error) {
      console.error('[SW] Push notification handling failed:', error)
    }
  }

  handleNotificationClick(event) {
    event.notification.close()
    
    const data = event.notification.data || {}
    let url = '/'
    
    // Determine URL based on notification type
    if (data.type === 'order_update' && data.order_id) {
      url = `/orders/${data.order_id}`
    } else if (data.type === 'menu_update' && data.menu_id) {
      url = `/menus/${data.menu_id}`
    } else if (data.url) {
      url = data.url
    }
    
    event.waitUntil(
      self.clients.matchAll({ type: 'window' }).then(clients => {
        // Check if there's already a window/tab open with the target URL
        for (const client of clients) {
          if (client.url === url && 'focus' in client) {
            return client.focus()
          }
        }
        
        // If not, open a new window/tab
        if (self.clients.openWindow) {
          return self.clients.openWindow(url)
        }
      })
    )
  }

  // IndexedDB helper methods (to be implemented with full offline data manager)
  async getOfflineOrders() {
    // Placeholder - will be implemented with IndexedDB integration
    return []
  }

  async removeOfflineOrder(id) {
    // Placeholder - will be implemented with IndexedDB integration
    console.log('[SW] Removing offline order:', id)
  }

  async getOfflineMenuUpdates() {
    // Placeholder - will be implemented with IndexedDB integration
    return []
  }

  async removeOfflineMenuUpdate(id) {
    // Placeholder - will be implemented with IndexedDB integration
    console.log('[SW] Removing offline menu update:', id)
  }

  async getOfflineAnalytics() {
    // Placeholder - will be implemented with IndexedDB integration
    return []
  }

  async clearOfflineAnalytics() {
    // Placeholder - will be implemented with IndexedDB integration
    console.log('[SW] Clearing offline analytics')
  }
}

// Initialize the service worker
new SmartMenuServiceWorker()

console.log('[SW] Smart Menu Service Worker loaded successfully')
