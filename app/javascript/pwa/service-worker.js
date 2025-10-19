/**
 * Smart Menu Service Worker
 * Provides offline functionality, caching, and background sync
 */

const CACHE_VERSION = '1.1.0'
const CACHE_NAME = `smart-menu-v${CACHE_VERSION}`
const STATIC_CACHE = `smart-menu-static-v${CACHE_VERSION}`
const DYNAMIC_CACHE = `smart-menu-dynamic-v${CACHE_VERSION}`
const API_CACHE = `smart-menu-api-v${CACHE_VERSION}`

// Cache size limits (in bytes)
const CACHE_LIMITS = {
  static: 50 * 1024 * 1024,    // 50MB
  dynamic: 25 * 1024 * 1024,   // 25MB
  api: 10 * 1024 * 1024        // 10MB
}

// Resources to cache immediately
const STATIC_RESOURCES = [
  '/',
  '/manifest.json',
  '/offline',
  '/icons/smart-menu-icon.png',
  '/icons/smart-menu-192.png',
  '/icons/smart-menu-512.png'
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
    this.version = '1.0.1'
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

  // Cache size management methods
  async getCacheSize(cacheName) {
    try {
      const cache = await caches.open(cacheName)
      const keys = await cache.keys()
      let totalSize = 0

      for (const request of keys) {
        const response = await cache.match(request)
        if (response) {
          const blob = await response.blob()
          totalSize += blob.size
        }
      }

      return totalSize
    } catch (error) {
      console.error('[SW] Error calculating cache size:', error)
      return 0
    }
  }

  async enforceCacheLimit(cacheName, limit) {
    try {
      const cache = await caches.open(cacheName)
      const keys = await cache.keys()
      
      // Calculate total size
      let totalSize = 0
      const entries = []

      for (const request of keys) {
        const response = await cache.match(request)
        if (response) {
          const blob = await response.blob()
          const size = blob.size
          totalSize += size
          
          // Get last accessed time from headers or use current time
          const lastAccessed = response.headers.get('X-Cache-Time') || Date.now()
          
          entries.push({
            request,
            size,
            lastAccessed: parseInt(lastAccessed)
          })
        }
      }

      // If over limit, remove least recently used entries
      if (totalSize > limit) {
        console.log(`[SW] Cache ${cacheName} over limit (${totalSize} > ${limit}), cleaning up...`)
        
        // Sort by last accessed (oldest first)
        entries.sort((a, b) => a.lastAccessed - b.lastAccessed)
        
        // Remove entries until under limit
        for (const entry of entries) {
          if (totalSize <= limit) break
          
          await cache.delete(entry.request)
          totalSize -= entry.size
          console.log(`[SW] Removed ${entry.request.url} (${entry.size} bytes)`)
        }
        
        console.log(`[SW] Cache cleaned up, new size: ${totalSize}`)
      }
    } catch (error) {
      console.error('[SW] Error enforcing cache limit:', error)
    }
  }

  async getCacheStats() {
    try {
      const stats = {
        static: await this.getCacheSize(this.caches.static),
        dynamic: await this.getCacheSize(this.caches.dynamic),
        api: await this.getCacheSize(this.caches.api)
      }

      const total = stats.static + stats.dynamic + stats.api
      
      console.log('[SW] Cache stats:', {
        static: `${(stats.static / 1024 / 1024).toFixed(2)} MB`,
        dynamic: `${(stats.dynamic / 1024 / 1024).toFixed(2)} MB`,
        api: `${(stats.api / 1024 / 1024).toFixed(2)} MB`,
        total: `${(total / 1024 / 1024).toFixed(2)} MB`
      })

      return stats
    } catch (error) {
      console.error('[SW] Error getting cache stats:', error)
      return { static: 0, dynamic: 0, api: 0 }
    }
  }

  async warmCache() {
    try {
      console.log('[SW] Warming cache with critical resources...')
      
      const cache = await caches.open(this.caches.dynamic)
      
      // Pre-cache critical pages
      const criticalPages = [
        '/restaurants',
        '/menus'
      ]

      for (const page of criticalPages) {
        try {
          const response = await fetch(page)
          if (response.ok) {
            await cache.put(page, response)
            console.log(`[SW] Cached: ${page}`)
          }
        } catch (error) {
          console.warn(`[SW] Failed to cache ${page}:`, error)
        }
      }

      console.log('[SW] Cache warming complete')
    } catch (error) {
      console.error('[SW] Error warming cache:', error)
    }
  }

  async purgeCache(pattern) {
    try {
      console.log(`[SW] Purging cache with pattern: ${pattern}`)
      
      const cacheNames = await caches.keys()
      let purgedCount = 0

      for (const cacheName of cacheNames) {
        const cache = await caches.open(cacheName)
        const keys = await cache.keys()

        for (const request of keys) {
          if (request.url.includes(pattern)) {
            await cache.delete(request)
            purgedCount++
          }
        }
      }

      console.log(`[SW] Purged ${purgedCount} cache entries`)
      return purgedCount
    } catch (error) {
      console.error('[SW] Error purging cache:', error)
      return 0
    }
  }
}

// Initialize the service worker
const sw = new SmartMenuServiceWorker()

// Expose cache management methods to clients
self.addEventListener('message', async (event) => {
  const { type, data } = event.data

  switch (type) {
    case 'GET_CACHE_STATS':
      const stats = await sw.getCacheStats()
      event.ports[0].postMessage({ type: 'CACHE_STATS', data: stats })
      break
      
    case 'WARM_CACHE':
      await sw.warmCache()
      event.ports[0].postMessage({ type: 'CACHE_WARMED' })
      break
      
    case 'PURGE_CACHE':
      const purgedCount = await sw.purgeCache(data.pattern)
      event.ports[0].postMessage({ type: 'CACHE_PURGED', data: { count: purgedCount } })
      break
      
    case 'SKIP_WAITING':
      self.skipWaiting()
      break
  }
})

console.log('[SW] Smart Menu Service Worker loaded successfully')
