// Modern, clean entry point for the Smart Menu application
// This replaces the monolithic application.js with a modular, maintainable architecture

// Note: Turbo is already loaded by the main application.js
// import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'

// Global dependencies
import jquery from 'jquery'
import * as bootstrap from 'bootstrap'
// import * as TabulatorModule from 'tabulator-tables'
// import * as TomSelectModule from 'tom-select'
import localTime from 'local-time'

// Core components will be loaded dynamically to avoid asset pipeline issues
// import { EventBus, AppEvents } from './utils/EventBus.js'
// import { FormManager } from './components/FormManager.js'
// import { TableManager } from './components/TableManager.js'
// import { performanceMonitor } from './utils/performance.js'

// Polyfill for Node.js globals that some libraries expect
window.process = window.process || { env: {} }

// Make libraries globally available
window.jQuery = window.$ = jquery
window.bootstrap = bootstrap

// Load libraries via script tags temporarily
const script1 = document.createElement('script')
script1.src = 'https://cdn.jsdelivr.net/npm/tom-select@2.3.1/dist/js/tom-select.complete.min.js'
script1.onload = () => console.log('TomSelect loaded:', typeof window.TomSelect)
document.head.appendChild(script1)

const script2 = document.createElement('script')
script2.src = 'https://cdn.jsdelivr.net/npm/tabulator-tables@5.5.2/dist/js/tabulator.min.js'
script2.onload = () => console.log('Tabulator loaded:', typeof window.Tabulator)
document.head.appendChild(script2)

// Start local-time
localTime.start()

// Initialize Stimulus
const application = Application.start()

// Register stimulus controllers manually for importmap compatibility
// Note: Controllers are loaded via importmap's pin_all_from directive
window.Stimulus = application

/**
 * Application Manager - Handles module loading and lifecycle
 */
class ApplicationManager {
  constructor() {
    this.modules = new Map()
    this.globalFormManager = null
    this.globalTableManager = null
    this.isInitialized = false
    this.EventBus = null
    this.AppEvents = null
    this.FormManager = null
    this.TableManager = null
    this.performanceMonitor = null
  }

  /**
   * Initialize the application
   */
  async init() {
    if (this.isInitialized) return

    console.log('[SmartMenu] Initializing application...')

    // Load core components dynamically
    await this.loadCoreComponents()

    // Initialize performance monitoring
    if (this.performanceMonitor) {
      this.performanceMonitor.init()
    }

    // Set up global event listeners
    this.setupGlobalEvents()

    // Initialize global managers
    this.initializeGlobalManagers()

    // Initialize page-specific modules
    await this.initializePageModules()

    this.isInitialized = true
    if (this.EventBus && this.AppEvents) {
      this.EventBus.emit(this.AppEvents.APP_READY)
    }

    // Log performance summary
    if (this.performanceMonitor) {
      const summary = this.performanceMonitor.getSummary()
      console.log('[SmartMenu] Application initialized successfully', summary)
    } else {
      console.log('[SmartMenu] Application initialized successfully')
    }
  }

  /**
   * Load core components dynamically (fallback to basic functionality if imports fail)
   */
  async loadCoreComponents() {
    console.log('[SmartMenu] Loading core components...')
    
    // Create basic EventBus fallback
    this.EventBus = {
      events: new Map(),
      on: function(event, callback) {
        if (!this.events.has(event)) {
          this.events.set(event, [])
        }
        this.events.get(event).push(callback)
      },
      emit: function(event, data) {
        if (this.events.has(event)) {
          this.events.get(event).forEach(callback => {
            try {
              callback({ detail: data })
            } catch (error) {
              console.error('EventBus callback error:', error)
            }
          })
        }
      },
      cleanup: function() {
        this.events.clear()
      },
      setDebugMode: function(enabled) {
        this.debug = enabled
      }
    }
    
    this.AppEvents = {
      APP_READY: 'app:ready',
      APP_DESTROY: 'app:destroy',
      COMPONENT_READY: 'component:ready',
      COMPONENT_DESTROY: 'component:destroy',
      PAGE_LOAD: 'page:load',
      PAGE_UNLOAD: 'page:unload',
      DATA_SAVE: 'data:save',
      RESTAURANT_SELECT: 'restaurant:select',
      MENU_SELECT: 'menu:select',
      MENUSECTION_SELECT: 'menusection:select',
      ORDER_UPDATE: 'order:update',
      ORDER_CREATE: 'order:create',
      PAYMENT_SUCCESS: 'payment:success'
    }

    // Create basic FormManager fallback
    this.FormManager = class BasicFormManager {
      constructor(container = document) {
        this.container = container
        this.isDestroyed = false
      }
      
      init() {
        console.log('[SmartMenu] Basic FormManager initialized')
        return this
      }
      
      refresh() {
        // Basic refresh logic
      }
      
      destroy() {
        this.isDestroyed = true
      }
      
      on() {
        // Basic event handling
      }
    }

    // Create basic TableManager fallback
    this.TableManager = class BasicTableManager {
      constructor(container = document) {
        this.container = container
        this.isDestroyed = false
      }
      
      init() {
        console.log('[SmartMenu] Basic TableManager initialized')
        return this
      }
      
      refresh() {
        // Basic refresh logic
      }
      
      destroy() {
        this.isDestroyed = true
      }
      
      refreshTable() {
        // Basic table refresh
      }
      
      getTable() {
        return null
      }
      
      initializeTable() {
        return null
      }
    }

    console.log('[SmartMenu] Basic components loaded successfully')
  }

  /**
   * Set up global event listeners
   */
  setupGlobalEvents() {
    if (!this.EventBus || !this.AppEvents) return;

    // Global error handling
    this.EventBus.on('api:error', (event) => {
      console.error('API Error:', event.detail.error)
      this.showNotification('An error occurred. Please try again.', 'error')
    })

    // Global notification handling
    this.EventBus.on('notify:success', (event) => {
      this.showNotification(event.detail.message, 'success')
    })

    this.EventBus.on('notify:error', (event) => {
      this.showNotification(event.detail.message, 'error')
    })

    this.EventBus.on('notify:warning', (event) => {
      this.showNotification(event.detail.message, 'warning')
    })

    this.EventBus.on('notify:info', (event) => {
      this.showNotification(event.detail.message, 'info')
    })

    // Component lifecycle logging
    this.EventBus.on(this.AppEvents.COMPONENT_READY, (event) => {
      console.log(`[SmartMenu] Component ready: ${event.detail.component}`)
    })
  }

  /**
   * Initialize global managers for fallback functionality
   */
  initializeGlobalManagers() {
    if (!this.FormManager || !this.TableManager) return;

    // Global form manager for any forms not handled by specific modules
    this.globalFormManager = new this.FormManager()
    this.globalFormManager.init()

    // Global table manager for any tables not handled by specific modules
    this.globalTableManager = new this.TableManager()
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
      
      let module;
      
      const loadModuleInstance = async () => {
        // For now, create basic module stubs to avoid import errors
        // The full modular system will be enabled once asset pipeline issues are resolved
        
        const BasicModule = class {
          constructor(name) {
            this.name = name
            this.isDestroyed = false
          }
          
          init() {
            console.log(`[SmartMenu] ${this.name} module initialized (basic mode)`)
            return this
          }
          
          refresh() {
            // Basic refresh
          }
          
          destroy() {
            this.isDestroyed = true
          }
        }
        
        switch (moduleName) {
        case 'restaurants':
          return new BasicModule('Restaurant')
        case 'menus':
          return new BasicModule('Menu')
        case 'employees':
          return new BasicModule('Employee')
        case 'menuitems':
          return new BasicModule('MenuItem')
        case 'menusections':
          return new BasicModule('MenuSection')
        case 'ordrs':
        case 'orders':
          return new BasicModule('Order')
        case 'inventories':
          return new BasicModule('Inventory')
        case 'ocr_menu_imports':
        case 'ocr':
          return new BasicModule('OcrMenuImport')
        case 'analytics':
          return new BasicModule('Analytics')
        case 'notifications':
          return new BasicModule('Notifications')
        case 'tracks':
          return new BasicModule('Tracks')
        case 'smartmenus':
          return new BasicModule('SmartMenus')
        case 'onboarding':
          return new BasicModule('Onboarding')
        default:
          console.warn(`[SmartMenu] Unknown module: ${moduleName}`)
          return null
        }
      };

      if (this.performanceMonitor) {
        module = await this.performanceMonitor.measureAsync(`load-${moduleName}`, loadModuleInstance)
      } else {
        module = await loadModuleInstance()
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
      },
      { 
        selector: '#sections-sortable, .ocr-import-form', 
        module: 'ocr' 
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
    if (this.EventBus) {
      this.EventBus.cleanup()
    }

    this.isInitialized = false
    if (this.EventBus && this.AppEvents) {
      this.EventBus.emit(this.AppEvents.APP_DESTROY)
    }
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

  // Basic TomSelect initialization for enhanced selects
  setTimeout(() => {
    if (window.TomSelect) {
      const selectElements = document.querySelectorAll('[data-tom-select="true"]')
      selectElements.forEach(element => {
        try {
          // Multiple checks to prevent double initialization
          const isAlreadyInitialized = 
            element.hasAttribute('data-tom-select-initialized') ||
            element.parentNode.classList.contains('ts-wrapper') ||
            element.classList.contains('tomselected') ||
            element.classList.contains('ts-hidden-accessible') ||
            element.tomSelect ||
            element.style.display === 'none' || // TomSelect hides original element
            element.hasAttribute('tabindex') && element.getAttribute('tabindex') === '-1' // TomSelect sets tabindex to -1
          
          // Debug logging to understand the state
          console.log('[SmartMenu] Checking TomSelect element:', {
            element: element,
            hasInitializedAttr: element.hasAttribute('data-tom-select-initialized'),
            hasWrapperParent: element.parentNode.classList.contains('ts-wrapper'),
            hasTomSelectedClass: element.classList.contains('tomselected'),
            hasHiddenClass: element.classList.contains('ts-hidden-accessible'),
            hasTomSelectProperty: !!element.tomSelect,
            isHidden: element.style.display === 'none',
            tabIndex: element.getAttribute('tabindex'),
            isAlreadyInitialized: isAlreadyInitialized
          })
          
          if (!isAlreadyInitialized) {
            const options = {
              plugins: ['remove_button'],
              create: element.dataset.creatable === 'true'
            }
            
            // Parse additional options from data attribute
            if (element.dataset.tomSelectOptions) {
              try {
                const additionalOptions = JSON.parse(element.dataset.tomSelectOptions)
                Object.assign(options, additionalOptions)
              } catch (e) {
                console.warn('Invalid TomSelect options JSON:', element.dataset.tomSelectOptions)
              }
            }
            
            const tomSelectInstance = new window.TomSelect(element, options)
            element.setAttribute('data-tom-select-initialized', 'true')
            element.tomSelect = tomSelectInstance
            
            console.log('[SmartMenu] TomSelect initialized on:', element)
          } else {
            console.log('[SmartMenu] TomSelect already initialized on:', element)
          }
        } catch (error) {
          console.warn('Failed to initialize TomSelect:', error)
        }
      })
    } else {
      console.warn('[SmartMenu] TomSelect not available')
    }
  }, 500)

  if (app.EventBus && app.AppEvents) {
    app.EventBus.emit(app.AppEvents.PAGE_LOAD)
  }
})

// Cleanup on navigation
document.addEventListener('turbo:before-cache', () => {
  console.log('[SmartMenu] Cleaning up before navigation')

  // Destroy tooltips and popovers
  document.querySelectorAll('.tooltip, .popover').forEach(el => el.remove())

  // Cleanup TomSelect instances
  document.querySelectorAll('[data-tom-select-initialized="true"]').forEach(element => {
    if (element.tomSelect && typeof element.tomSelect.destroy === 'function') {
      try {
        element.tomSelect.destroy()
        element.removeAttribute('data-tom-select-initialized')
        delete element.tomSelect
        console.log('[SmartMenu] TomSelect cleaned up on:', element)
      } catch (error) {
        console.warn('Failed to cleanup TomSelect:', error)
      }
    }
  })

  // Refresh modules instead of destroying (for better performance)
  app.refresh()

  if (app.EventBus && app.AppEvents) {
    app.EventBus.emit(app.AppEvents.PAGE_UNLOAD)
  }
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

// EventBus will be available after app initialization
setTimeout(() => {
  if (app.EventBus) {
    window.EventBus = app.EventBus
    
    // Enable EventBus debug mode in development
    if (process.env.NODE_ENV === 'development') {
      app.EventBus.setDebugMode(true)
    }
  }
}, 1000)

console.log('[SmartMenu] Application script loaded')
