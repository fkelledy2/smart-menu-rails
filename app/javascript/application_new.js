// Modern, clean entry point for the Smart Menu application
// This replaces the monolithic application.js with a modular, maintainable architecture

import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers'

// Global dependencies
import jquery from 'jquery'
import * as bootstrap from 'bootstrap'
import { TabulatorFull as Tabulator } from 'tabulator-tables'
import TomSelect from 'tom-select'
import localTime from 'local-time'

// Core components
import { EventBus, AppEvents } from './utils/EventBus.js'
import { FormManager } from './components/FormManager.js'
import { TableManager } from './components/TableManager.js'

// Make libraries globally available
window.jQuery = window.$ = jquery
window.bootstrap = bootstrap
window.Tabulator = Tabulator
window.TomSelect = TomSelect

// Start local-time
localTime.start()

// Initialize Stimulus
const application = Application.start()
const context = require.context('./controllers', true, /\.js$/)
application.load(definitionsFromContext(context))

/**
 * Application Manager - Handles module loading and lifecycle
 */
class ApplicationManager {
  constructor() {
    this.modules = new Map()
    this.globalFormManager = null
    this.globalTableManager = null
    this.isInitialized = false
  }

  /**
   * Initialize the application
   */
  async init() {
    if (this.isInitialized) return

    console.log('[SmartMenu] Initializing application...')

    // Set up global event listeners
    this.setupGlobalEvents()

    // Initialize global managers
    this.initializeGlobalManagers()

    // Initialize page-specific modules
    await this.initializePageModules()

    this.isInitialized = true
    EventBus.emit(AppEvents.APP_READY)

    console.log('[SmartMenu] Application initialized successfully')
  }

  /**
   * Set up global event listeners
   */
  setupGlobalEvents() {
    // Global error handling
    EventBus.on('api:error', (event) => {
      console.error('API Error:', event.detail.error)
      this.showNotification('An error occurred. Please try again.', 'error')
    })

    // Global notification handling
    EventBus.on('notify:success', (event) => {
      this.showNotification(event.detail.message, 'success')
    })

    EventBus.on('notify:error', (event) => {
      this.showNotification(event.detail.message, 'error')
    })

    EventBus.on('notify:warning', (event) => {
      this.showNotification(event.detail.message, 'warning')
    })

    EventBus.on('notify:info', (event) => {
      this.showNotification(event.detail.message, 'info')
    })

    // Component lifecycle logging
    EventBus.on(AppEvents.COMPONENT_READY, (event) => {
      console.log(`[SmartMenu] Component ready: ${event.detail.component}`)
    })
  }

  /**
   * Initialize global managers for fallback functionality
   */
  initializeGlobalManagers() {
    // Global form manager for any forms not handled by specific modules
    this.globalFormManager = new FormManager()
    this.globalFormManager.init()

    // Global table manager for any tables not handled by specific modules
    this.globalTableManager = new TableManager()
    this.globalTableManager.init()
  }

  /**
   * Initialize page-specific modules based on body data attributes
   */
  async initializePageModules() {
    const pageModules = document.body.dataset.modules?.split(',') || []
    
    for (const moduleName of pageModules) {
      await this.loadModule(moduleName.trim())
    }

    // Auto-detect modules based on page content
    await this.autoDetectModules()
  }

  /**
   * Load a specific module
   */
  async loadModule(moduleName) {
    if (this.modules.has(moduleName)) {
      return this.modules.get(moduleName)
    }

    try {
      console.log(`[SmartMenu] Loading module: ${moduleName}`)
      
      let module
      switch (moduleName) {
        case 'restaurants':
          const { RestaurantModule } = await import('./modules/restaurants/RestaurantModule.js')
          module = RestaurantModule.init()
          break
        
        case 'menus':
          const { MenuModule } = await import('./modules/menus/MenuModule.js')
          module = MenuModule.init()
          break
        
        case 'employees':
          const { EmployeeModule } = await import('./modules/employees/EmployeeModule.js')
          module = EmployeeModule.init()
          break
        
        case 'menuitems':
          const { MenuItemModule } = await import('./modules/menuitems/MenuItemModule.js')
          module = MenuItemModule.init()
          break
        
        case 'menusections':
          const { MenuSectionModule } = await import('./modules/menusections/MenuSectionModule.js')
          module = MenuSectionModule.init()
          break
        
        default:
          console.warn(`[SmartMenu] Unknown module: ${moduleName}`)
          return null
      }

      if (module) {
        this.modules.set(moduleName, module)
        console.log(`[SmartMenu] Module loaded: ${moduleName}`)
      }

      return module
    } catch (error) {
      console.error(`[SmartMenu] Failed to load module ${moduleName}:`, error)
      return null
    }
  }

  /**
   * Auto-detect modules based on page content
   */
  async autoDetectModules() {
    const detectionRules = [
      { 
        selector: '#restaurant-table, .restaurant-form, .qrSlug', 
        module: 'restaurants' 
      },
      { 
        selector: '#menu-table, .menu-form', 
        module: 'menus' 
      },
      { 
        selector: '#menuitem-table, .menuitem-form', 
        module: 'menuitems' 
      },
      { 
        selector: '#employee-table, .employee-form', 
        module: 'employees' 
      },
      { 
        selector: '#order-table, .order-form', 
        module: 'orders' 
      }
    ]

    for (const rule of detectionRules) {
      if (document.querySelector(rule.selector) && !this.modules.has(rule.module)) {
        await this.loadModule(rule.module)
      }
    }
  }

  /**
   * Show notification to user
   */
  showNotification(message, type = 'info') {
    // Create toast notification
    const toastContainer = this.getOrCreateToastContainer()
    
    const toast = document.createElement('div')
    toast.className = `toast align-items-center text-white bg-${this.getBootstrapColorClass(type)} border-0`
    toast.setAttribute('role', 'alert')
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `

    toastContainer.appendChild(toast)
    
    const bsToast = new bootstrap.Toast(toast, { delay: 5000 })
    bsToast.show()

    // Clean up after toast is hidden
    toast.addEventListener('hidden.bs.toast', () => {
      toast.remove()
    })
  }

  /**
   * Get or create toast container
   */
  getOrCreateToastContainer() {
    let container = document.querySelector('.toast-container')
    
    if (!container) {
      container = document.createElement('div')
      container.className = 'toast-container position-fixed top-0 end-0 p-3'
      container.style.zIndex = '1055'
      document.body.appendChild(container)
    }
    
    return container
  }

  /**
   * Convert notification type to Bootstrap color class
   */
  getBootstrapColorClass(type) {
    const colorMap = {
      success: 'success',
      error: 'danger',
      warning: 'warning',
      info: 'info'
    }
    return colorMap[type] || 'info'
  }

  /**
   * Refresh all modules
   */
  refresh() {
    this.modules.forEach(module => {
      if (module && typeof module.refresh === 'function') {
        module.refresh()
      }
    })
  }

  /**
   * Destroy all modules and clean up
   */
  destroy() {
    console.log('[SmartMenu] Destroying application...')

    // Destroy all modules
    this.modules.forEach(module => {
      if (module && typeof module.destroy === 'function') {
        module.destroy()
      }
    })
    this.modules.clear()

    // Destroy global managers
    if (this.globalFormManager) {
      this.globalFormManager.destroy()
    }
    if (this.globalTableManager) {
      this.globalTableManager.destroy()
    }

    // Clean up global event listeners
    EventBus.cleanup()

    this.isInitialized = false
    EventBus.emit(AppEvents.APP_DESTROY)
  }
}

// Create global application instance
const app = new ApplicationManager()

// Enhanced Turbo event handling
document.addEventListener('turbo:load', async () => {
  console.log('[SmartMenu] Page loaded')

  // Initialize Bootstrap components
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltips.forEach(el => new bootstrap.Tooltip(el))
  
  const popovers = document.querySelectorAll('[data-bs-toggle="popover"]')
  popovers.forEach(el => new bootstrap.Popover(el))

  // Initialize application
  await app.init()

  EventBus.emit(AppEvents.PAGE_LOAD)
})

// Cleanup on navigation
document.addEventListener('turbo:before-cache', () => {
  console.log('[SmartMenu] Cleaning up before navigation')

  // Destroy tooltips and popovers
  document.querySelectorAll('.tooltip, .popover').forEach(el => el.remove())

  // Refresh modules instead of destroying (for better performance)
  app.refresh()

  EventBus.emit(AppEvents.PAGE_UNLOAD)
})

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  app.destroy()
})

// Global utility functions (minimal, modern alternatives)
window.patch = async (url, body) => {
  const { patch } = await import('./utils/api.js')
  return patch(url, body)
}

window.del = async (url) => {
  const { del } = await import('./utils/api.js')
  return del(url)
}

// Export for debugging
window.SmartMenuApp = app
window.EventBus = EventBus

// Enable EventBus debug mode in development
if (process.env.NODE_ENV === 'development') {
  EventBus.setDebugMode(true)
}

console.log('[SmartMenu] Application script loaded')
