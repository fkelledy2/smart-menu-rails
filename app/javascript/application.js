// Main entry point for the Smart Menu application
// Modern, modular JavaScript architecture with enhanced functionality
// VERSION: 2025.11.03.2314 - Auto-save routing fix

// Initialize Sentry error tracking (must be first)
import './sentry';

console.log('[SmartMenu] Loading application.js v2025.11.03.2314');

// Global error handler for module resolution issues
window.addEventListener('error', (event) => {
  if (
    event.message &&
    (event.message.includes('Failed to resolve module specifier') ||
      (event.message.includes('application') && event.message.includes('Relative references')))
  ) {
    console.warn('[SmartMenu] Module resolution error caught:', event.message);
    console.warn(
      '[SmartMenu] This is likely due to importmap/controller conflicts - continuing with available modules...'
    );
    event.preventDefault(); // Prevent the error from breaking the application
    return false;
  }
});

// Handle unhandled promise rejections (for dynamic imports)
window.addEventListener('unhandledrejection', (event) => {
  if (
    event.reason &&
    event.reason.message &&
    event.reason.message.includes('Failed to resolve module specifier')
  ) {
    console.warn('[SmartMenu] Module import promise rejection caught:', event.reason.message);
    console.warn('[SmartMenu] Continuing with available modules...');
    event.preventDefault(); // Prevent the error from breaking the application
  }
});

// Import Turbo since this is now the only system
import '@hotwired/turbo-rails';
import { Application } from '@hotwired/stimulus';

// Import Stimulus controllers
import './controllers';

// Import enhanced restaurant context system
import RestaurantContext from './utils/RestaurantContext.js';

// Global dependencies
import jquery from 'jquery';
import * as bootstrap from 'bootstrap';
import { TabulatorFull as Tabulator } from 'tabulator-tables';
import TomSelect from 'tom-select';
import localTime from 'local-time';
import QRCodeStyling from 'qr-code-styling';

// Import all the initialization functions like the old system
import { initTomSelectIfNeeded } from './tomselect_helper';
import { initialiseSlugs, initRestaurants } from './restaurants';
import { initTips } from './tips';
import { initTestimonials } from './testimonials';
import { initTaxes } from './taxes';
import { initTablesettings } from './tablesettings';
import { initSizes } from './sizes';
import { initRestaurantlocales } from './restaurantlocales';
import { initRestaurantavailabilities } from './restaurantavailabilities';
import { initOrders } from './ordrs';
import { initOrdritems } from './ordritems';
import { initMetrics } from './metrics';
import { initMenusections } from './menusections';
import { initMenus } from './menus';
import { initMenuitems } from './menuitems';
import { initMenuavailabilities } from './menuavailabilities';
import { initEmployees } from './employees';
import { initDW } from './dw_orders_mv';
import { initAllergyns } from './allergyns';
import { initSmartmenus } from './smartmenus';
import { initTags } from './tags';
import { initOCRMenuImportDnD } from './ocr_menu_imports';
import { initiInventories } from './inventories';

// Import additional dependencies
import { DateTime } from 'luxon';
import '@rails/request.js';
import './add_jquery';
import './channels';
import { OrderingModule } from './modules/restaurants/OrderingModule.js';

// Import hero carousel for homepage
import './modules/hero_carousel.js';

// Make additional libraries available globally
window.DateTime = DateTime;

// Polyfill for Node.js globals that some libraries expect
window.process = window.process || { env: {} };

// Make libraries available globally
window.$ = window.jQuery = jquery;
window.bootstrap = bootstrap;
window.Tabulator = Tabulator;
window.TomSelect = TomSelect;
window.QRCodeStyling = QRCodeStyling;
window.OrderingModule = OrderingModule;

// Make initialization functions available globally for inline scripts
window.initialiseSlugs = initialiseSlugs;

console.log(
  '[SmartMenu] Libraries loaded - TomSelect:',
  typeof window.TomSelect,
  'Tabulator:',
  typeof window.Tabulator
);

// Start local-time
localTime.start();

// Initialize Stimulus
const application = Application.start();

// Import and register Stimulus controllers like the old system
try {
  import('./controllers')
    .then(() => console.log('[SmartMenu] Controllers loaded successfully'))
    .catch((error) => {
      console.warn('[SmartMenu] Controllers import failed:', error.message);
      console.warn('[SmartMenu] Continuing without controller auto-loading...');
    });
} catch (error) {
  console.warn('[SmartMenu] Controllers import error:', error.message);
}

import MenuImportController from './controllers/menu_import_controller.js';
application.register('menu-import', MenuImportController);

import SidebarController from './controllers/sidebar_controller.js';
application.register('sidebar', SidebarController);

import AutoSaveController from './controllers/auto_save_controller.js';
application.register('auto-save', AutoSaveController);
console.log('[SmartMenu] Auto-save controller registered');

// Register stimulus controllers manually for importmap compatibility
// Note: Controllers are loaded via importmap's pin_all_from directive
window.Stimulus = application;

/**
 * Application Manager - Handles module loading and lifecycle
 */
class ApplicationManager {
  constructor() {
    this.modules = new Map();
    this.globalFormManager = null;
    this.globalTableManager = null;
    this.isInitialized = false;
    this.EventBus = null;
    this.AppEvents = null;
    this.FormManager = null;
    this.TableManager = null;
    this.performanceMonitor = null;
  }

  /**
   * Initialize the application
   */
  async init() {
    if (this.isInitialized) return;

    console.log('[SmartMenu] Initializing application...');

    // Load core components dynamically
    await this.loadCoreComponents();

    // Initialize performance monitoring
    if (this.performanceMonitor) {
      this.performanceMonitor.init();
    }

    // Set up global event listeners
    this.setupGlobalEvents();

    // Initialize global managers
    this.initializeGlobalManagers();

    // Initialize page-specific modules
    await this.initializePageModules();

    this.isInitialized = true;
    if (this.EventBus && this.AppEvents) {
      this.EventBus.emit(this.AppEvents.APP_READY);
    }

    // Log performance summary
    if (this.performanceMonitor) {
      const summary = this.performanceMonitor.getSummary();
      console.log('[SmartMenu] Application initialized successfully v2025.11.03.2314', summary);
    } else {
      console.log('[SmartMenu] Application initialized successfully v2025.11.03.2314');
    }
  }

  /**
   * Load core components dynamically (fallback to basic functionality if imports fail)
   */
  async loadCoreComponents() {
    console.log('[SmartMenu] Loading core components...');

    // Create basic EventBus fallback
    this.EventBus = {
      events: new Map(),
      on: function (event, callback) {
        if (!this.events.has(event)) {
          this.events.set(event, []);
        }
        this.events.get(event).push(callback);
      },
      emit: function (event, data) {
        if (this.events.has(event)) {
          this.events.get(event).forEach((callback) => {
            try {
              callback({ detail: data });
            } catch (error) {
              console.error('EventBus callback error:', error);
            }
          });
        }
      },
      cleanup: function () {
        this.events.clear();
      },
      setDebugMode: function (enabled) {
        this.debug = enabled;
      },
    };

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
      PAYMENT_SUCCESS: 'payment:success',
    };

    // Create basic FormManager fallback with auto-save support
    this.FormManager = class BasicFormManager {
      constructor(container = document) {
        this.container = container;
        this.isDestroyed = false;
        this.saveTimeouts = new Map();
      }

      init() {
        console.log('[SmartMenu] Basic FormManager initialized');
        this.initializeAutoSave();
        return this;
      }

      initializeAutoSave() {
        // Find all forms with data-auto-save attribute
        const autoSaveForms = this.container.querySelectorAll('form[data-auto-save="true"]');
        
        autoSaveForms.forEach((form) => {
          const saveDelay = parseInt(form.dataset.autoSaveDelay) || 2000;
          
          const debouncedSave = () => {
            // Clear existing timeout for this form
            if (this.saveTimeouts.has(form)) {
              clearTimeout(this.saveTimeouts.get(form));
            }
            
            // Set new timeout
            const timeoutId = setTimeout(() => {
              this.autoSaveForm(form);
            }, saveDelay);
            
            this.saveTimeouts.set(form, timeoutId);
          };
          
          // Bind to all form inputs
          const inputs = form.querySelectorAll('input, select, textarea');
          inputs.forEach((input) => {
            input.addEventListener('input', debouncedSave);
            input.addEventListener('change', debouncedSave);
          });
          
          console.log('[SmartMenu] Auto-save enabled for form:', form.action);
        });
      }

      async autoSaveForm(form) {
        try {
          const formData = new FormData(form);
          const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
          
          // Use form.action if it's set correctly, otherwise construct from pathname
          let url = form.action;
          
          // If form.action is empty or contains /edit, reconstruct it
          if (!url || url.includes('/edit')) {
            const pathname = window.location.pathname.replace(/\/edit.*$/, '');
            url = window.location.origin + pathname;
          }
          
          console.log('[SmartMenu] Form action:', form.action);
          console.log('[SmartMenu] Final URL for PATCH:', url);
          console.log('[SmartMenu] Using XMLHttpRequest to bypass fetch interceptors');
          
          // Use XMLHttpRequest instead of fetch to avoid browser extension interference
          const response = await new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open('PATCH', url);
            xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
            xhr.setRequestHeader('X-CSRF-Token', csrfToken || '');
            xhr.setRequestHeader('Accept', 'application/json');
            
            xhr.onload = () => {
              console.log('[SmartMenu] XHR completed, status:', xhr.status);
              resolve({
                ok: xhr.status >= 200 && xhr.status < 300,
                status: xhr.status,
                json: async () => JSON.parse(xhr.responseText || '{}')
              });
            };
            
            xhr.onerror = () => {
              console.error('[SmartMenu] XHR error');
              reject(new Error('Network error'));
            };
            
            console.log('[SmartMenu] Sending XHR to:', url);
            xhr.send(formData);
          });

          if (response.ok) {
            console.log('[SmartMenu] Form auto-saved successfully');
            this.showSaveIndicator(form, 'saved');
          } else {
            console.error('[SmartMenu] Auto-save failed:', response.status);
            this.showSaveIndicator(form, 'error');
          }
        } catch (error) {
          console.error('[SmartMenu] Auto-save error:', error);
          this.showSaveIndicator(form, 'error');
        }
      }

      showSaveIndicator(form, status) {
        // Show a temporary save indicator
        let indicator = form.querySelector('.auto-save-indicator');
        if (!indicator) {
          indicator = document.createElement('div');
          indicator.className = 'auto-save-indicator';
          indicator.style.cssText = 'position: fixed; top: 20px; right: 20px; padding: 12px 20px; border-radius: 6px; z-index: 9999; font-size: 14px; transition: opacity 0.3s;';
          form.appendChild(indicator);
        }
        
        if (status === 'saved') {
          indicator.textContent = '✓ Saved';
          indicator.style.backgroundColor = '#10b981';
          indicator.style.color = 'white';
        } else if (status === 'error') {
          indicator.textContent = '✗ Save failed';
          indicator.style.backgroundColor = '#ef4444';
          indicator.style.color = 'white';
        }
        
        indicator.style.opacity = '1';
        
        // Fade out after 2 seconds
        setTimeout(() => {
          indicator.style.opacity = '0';
          setTimeout(() => indicator.remove(), 300);
        }, 2000);
      }

      refresh() {
        // Re-initialize auto-save for any new forms
        this.initializeAutoSave();
      }

      destroy() {
        // Clear all timeouts
        this.saveTimeouts.forEach((timeoutId) => clearTimeout(timeoutId));
        this.saveTimeouts.clear();
        this.isDestroyed = true;
      }

      on() {
        // Basic event handling
      }
    };

    // Create basic TableManager fallback
    this.TableManager = class BasicTableManager {
      constructor(container = document) {
        this.container = container;
        this.isDestroyed = false;
      }

      init() {
        console.log('[SmartMenu] Basic TableManager initialized');
        return this;
      }

      refresh() {
        // Basic refresh logic
      }

      destroy() {
        this.isDestroyed = true;
      }

      refreshTable() {
        // Basic table refresh
      }

      getTable() {
        return null;
      }

      initializeTable() {
        return null;
      }
    };

    console.log('[SmartMenu] Basic components loaded successfully');
  }

  /**
   * Set up global event listeners
   */
  setupGlobalEvents() {
    if (!this.EventBus || !this.AppEvents) return;

    // Global error handling
    this.EventBus.on('api:error', (event) => {
      console.error('API Error:', event.detail.error);
      this.showNotification('An error occurred. Please try again.', 'error');
    });

    // Global notification handling
    this.EventBus.on('notify:success', (event) => {
      this.showNotification(event.detail.message, 'success');
    });

    this.EventBus.on('notify:error', (event) => {
      this.showNotification(event.detail.message, 'error');
    });

    this.EventBus.on('notify:warning', (event) => {
      this.showNotification(event.detail.message, 'warning');
    });

    this.EventBus.on('notify:info', (event) => {
      this.showNotification(event.detail.message, 'info');
    });

    // Component lifecycle logging
    this.EventBus.on(this.AppEvents.COMPONENT_READY, (event) => {
      console.log(`[SmartMenu] Component ready: ${event.detail.component}`);
    });
  }

  /**
   * Initialize global managers for fallback functionality
   */
  initializeGlobalManagers() {
    if (!this.FormManager || !this.TableManager) return;

    // Global form manager for any forms not handled by specific modules
    this.globalFormManager = new this.FormManager();
    this.globalFormManager.init();

    // Global table manager for any tables not handled by specific modules
    this.globalTableManager = new this.TableManager();
    this.globalTableManager.init();
  }

  /**
   * Initialize page-specific modules based on body data attributes
   */
  async initializePageModules() {
    const pageModules = document.body.dataset.modules?.split(',') || [];

    for (const moduleName of pageModules) {
      await this.loadModule(moduleName.trim());
    }

    // Auto-detect modules based on page content
    await this.autoDetectModules();
  }

  /**
   * Load a specific module
   */
  async loadModule(moduleName) {
    if (this.modules.has(moduleName)) {
      return this.modules.get(moduleName);
    }

    try {
      console.log(`[SmartMenu] Loading module: ${moduleName}`);

      let module;

      const loadModuleInstance = async () => {
        // For now, create basic module stubs to avoid import errors
        // The full modular system will be enabled once asset pipeline issues are resolved

        const BasicModule = class {
          constructor(name) {
            this.name = name;
            this.isDestroyed = false;
          }

          init() {
            console.log(`[SmartMenu] ${this.name} module initialized (basic mode)`);
            return this;
          }

          refresh() {
            // Basic refresh
          }

          destroy() {
            this.isDestroyed = true;
          }
        };

        switch (moduleName) {
          case 'restaurants':
            return new BasicModule('Restaurant');
          case 'menus':
            return new BasicModule('Menu');
          case 'employees':
            return new BasicModule('Employee');
          case 'menuitems':
            return new BasicModule('MenuItem');
          case 'menusections':
            return new BasicModule('MenuSection');
          case 'ordrs':
          case 'orders':
            return new BasicModule('Order');
          case 'inventories':
            return new BasicModule('Inventory');
          case 'ocr_menu_imports':
          case 'ocr':
            return new BasicModule('OcrMenuImport');
          case 'analytics':
            return new BasicModule('Analytics');
          case 'notifications':
            return new BasicModule('Notifications');
          case 'tracks':
            return new BasicModule('Tracks');
          case 'smartmenus':
            return new BasicModule('SmartMenus');
          case 'onboarding':
            return new BasicModule('Onboarding');
          default:
            console.warn(`[SmartMenu] Unknown module: ${moduleName}`);
            return null;
        }
      };

      if (this.performanceMonitor) {
        module = await this.performanceMonitor.measureAsync(
          `load-${moduleName}`,
          loadModuleInstance
        );
      } else {
        module = await loadModuleInstance();
      }

      if (module) {
        this.modules.set(moduleName, module);
        console.log(`[SmartMenu] Module loaded: ${moduleName}`);
      }

      return module;
    } catch (error) {
      console.error(`[SmartMenu] Failed to load module ${moduleName}:`, error);
      return null;
    }
  }

  /**
   * Auto-detect modules based on page content
   */
  async autoDetectModules() {
    const detectionRules = [
      {
        selector: '#restaurant-table, .restaurant-form, .qrSlug',
        module: 'restaurants',
      },
      {
        selector: '#menu-table, .menu-form',
        module: 'menus',
      },
      {
        selector: '#menuitem-table, .menuitem-form',
        module: 'menuitems',
      },
      {
        selector: '#employee-table, .employee-form',
        module: 'employees',
      },
      {
        selector: '#order-table, .order-form',
        module: 'orders',
      },
      {
        selector: '#sections-sortable, .ocr-import-form',
        module: 'ocr',
      },
    ];

    for (const rule of detectionRules) {
      if (document.querySelector(rule.selector) && !this.modules.has(rule.module)) {
        await this.loadModule(rule.module);
      }
    }

    // Ordering dashboard: initialize charts module if present
    try {
      const odRoot = document.querySelector('#ordering-dashboard');
      if (odRoot && window.OrderingModule) {
        if (odRoot.dataset.odInitialized !== 'true') {
          odRoot.dataset.odInitialized = 'true';
          console.log('[SmartMenu] Initializing OrderingModule via auto-detect');
          window.OrderingModule.init(document);
        }
      }

      // Observe DOM for later insertion (e.g., Turbo Frames) and initialize once
      if (!window.__odObserverAttached) {
        window.__odObserverAttached = true;
        const observer = new MutationObserver(() => {
          const el = document.querySelector('#ordering-dashboard');
          if (el && window.OrderingModule && el.dataset.odInitialized !== 'true') {
            el.dataset.odInitialized = 'true';
            console.log('[SmartMenu] Initializing OrderingModule via MutationObserver');
            try { window.OrderingModule.init(document); } catch (e) { console.warn('OrderingModule init via observer failed', e); }
          }
        });
        observer.observe(document.documentElement || document.body, { childList: true, subtree: true });
      }
    } catch (e) {
      console.warn('[SmartMenu] OrderingModule auto-init failed', e);
    }
  }

  /**
   * Show notification to user
   */
  showNotification(message, type = 'info') {
    // Create toast notification
    const toastContainer = this.getOrCreateToastContainer();

    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${this.getBootstrapColorClass(type)} border-0`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;

    toastContainer.appendChild(toast);

    const bsToast = new bootstrap.Toast(toast, { delay: 5000 });
    bsToast.show();

    // Clean up after toast is hidden
    toast.addEventListener('hidden.bs.toast', () => {
      toast.remove();
    });
  }

  /**
   * Get or create toast container
   */
  getOrCreateToastContainer() {
    let container = document.querySelector('.toast-container');

    if (!container) {
      container = document.createElement('div');
      container.className = 'toast-container position-fixed top-0 end-0 p-3';
      container.style.zIndex = '1055';
      document.body.appendChild(container);
    }

    return container;
  }

  /**
   * Convert notification type to Bootstrap color class
   */
  getBootstrapColorClass(type) {
    const colorMap = {
      success: 'success',
      error: 'danger',
      warning: 'warning',
      info: 'info',
    };
    return colorMap[type] || 'info';
  }

  /**
   * Refresh all modules
   */
  refresh() {
    this.modules.forEach((module) => {
      if (module && typeof module.refresh === 'function') {
        module.refresh();
      }
    });
  }

  /**
   * Destroy all modules and clean up
   */
  destroy() {
    console.log('[SmartMenu] Destroying application...');

    // Destroy all modules
    this.modules.forEach((module) => {
      if (module && typeof module.destroy === 'function') {
        module.destroy();
      }
    });
    this.modules.clear();

    // Destroy global managers
    if (this.globalFormManager) {
      this.globalFormManager.destroy();
    }
    if (this.globalTableManager) {
      this.globalTableManager.destroy();
    }

    // Clean up global event listeners
    if (this.EventBus) {
      this.EventBus.cleanup();
    }

    this.isInitialized = false;
    if (this.EventBus && this.AppEvents) {
      this.EventBus.emit(this.AppEvents.APP_DESTROY);
    }
  }
}

// Create global application instance
const app = new ApplicationManager();

// Note: Turbo event handling is done in the main turboLoadHandler below

// Add the missing utility functions from application.js
export function patch(url, body) {
  fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
    },
    body: JSON.stringify(body),
  });
}

// Make patch function available globally
window.patch = patch;

export function del(url) {
  fetch(url, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
    },
  });
}

// Make del function available globally
window.del = del;

export function validateIntegerInput(input) {
  input.value = input.value.replace(/[^0-9]/g, '');
}

window.fadeIn = function (obj) {
  $(obj).fadeIn(1000);
};

// Initialize TomSelect on user_plan if it exists (like in application.js)
if ($('#user_plan').length) {
  setTimeout(() => {
    if (window.TomSelect) {
      new window.TomSelect('#user_plan', {});
    }
  }, 1500); // After other TomSelect initialization
}

// Cleanup on navigation
document.addEventListener('turbo:before-cache', () => {
  console.log('[SmartMenu] Cleaning up before navigation');

  // Destroy tooltips and popovers
  document.querySelectorAll('.tooltip, .popover').forEach((el) => el.remove());

  // Cleanup TomSelect instances
  document.querySelectorAll('[data-tom-select-initialized="true"]').forEach((element) => {
    if (element.tomSelect && typeof element.tomSelect.destroy === 'function') {
      try {
        element.tomSelect.destroy();
        element.removeAttribute('data-tom-select-initialized');
        delete element.tomSelect;
        console.log('[SmartMenu] TomSelect cleaned up on:', element);
      } catch (error) {
        console.warn('Failed to cleanup TomSelect:', error);
      }
    }
  });

  // Refresh modules instead of destroying (for better performance)
  app.refresh();

  if (app.EventBus && app.AppEvents) {
    app.EventBus.emit(app.AppEvents.PAGE_UNLOAD);
  }
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  app.destroy();
});

// Global utility functions (minimal, modern alternatives)
window.patch = async (url, body) => {
  const { patch } = await import('./utils/api.js');
  return patch(url, body);
};

window.del = async (url) => {
  const { del } = await import('./utils/api.js');
  return del(url);
};

// Export for debugging
window.SmartMenuApp = app;

// EventBus will be available after app initialization
setTimeout(() => {
  if (app.EventBus) {
    window.EventBus = app.EventBus;

    // Enable EventBus debug mode in development
    if (process.env.NODE_ENV === 'development') {
      app.EventBus.setDebugMode(true);
    }
  }
}, 1000);

// Enhanced turbo:load event listener with detailed logging (like application.js)
let turboLoadCount = 0;
const turboLoadHandler = async (event) => {
  turboLoadCount++;
  console.group(`turbo:load #${turboLoadCount}`);

  // Wait for libraries to load
  let attempts = 0;
  while ((!window.Tabulator || !window.TomSelect) && attempts < 50) {
    await new Promise((resolve) => setTimeout(resolve, 100));
    attempts++;
  }

  // Call the page initialization function that was defined above
  const initializePageFunction = async () => {
    // Initialize Bootstrap dropdowns since we're the active system
    console.log('[SmartMenu] Initializing Bootstrap components');

    // Initialize dropdowns
    const dropdowns = document.querySelectorAll('[data-bs-toggle="dropdown"]');
    console.log(`[SmartMenu] Found ${dropdowns.length} dropdown elements`);

    dropdowns.forEach((el) => {
      if (!el.hasAttribute('data-bs-dropdown-initialized')) {
        try {
          // Ensure the element is visible and not disabled
          if (el.offsetParent === null) {
            console.warn(
              '[SmartMenu] Dropdown element is hidden, skipping:',
              el.id || el.className
            );
            return;
          }

          // Check if element has proper structure
          const dropdownMenu = el.nextElementSibling;
          if (!dropdownMenu || !dropdownMenu.classList.contains('dropdown-menu')) {
            console.warn(
              '[SmartMenu] Dropdown missing dropdown-menu sibling:',
              el.id || el.className
            );
          }

          const dropdownInstance = new bootstrap.Dropdown(el);
          el.setAttribute('data-bs-dropdown-initialized', 'true');
          el._dropdownInstance = dropdownInstance;

          console.log('[SmartMenu] Bootstrap dropdown initialized on:', el.id || el.className);
        } catch (error) {
          console.error('[SmartMenu] Failed to initialize dropdown:', error, el);
        }
      } else {
        console.log('[SmartMenu] Dropdown already initialized:', el.id || el.className);
      }
    });

    // Initialize tooltips
    const tooltips = document.querySelectorAll(
      '[data-bs-toggle="tooltip"]:not([data-bs-original-title])'
    );
    tooltips.forEach((el) => new bootstrap.Tooltip(el));

    // Initialize popovers
    const popovers = document.querySelectorAll(
      '[data-bs-toggle="popover"]:not([data-bs-original-title])'
    );
    popovers.forEach((el) => new bootstrap.Popover(el));

    // Initialize all components like the old system
    console.log('init');

    // Initialize all components in the same order as application.js
    try {
      initialiseSlugs();
      initRestaurants();
      initTips();
      initTestimonials();
      initTaxes();
      initTablesettings();
      initSizes();
      initRestaurantlocales();
      initRestaurantavailabilities();
      initOrders();
      initOrdritems();
      initMetrics();
      initMenusections(); // This initializes Tabulator tables!
      initMenus();
      initMenuitems();
      initMenuavailabilities();
      initEmployees();
      initDW();
      initAllergyns();
      initSmartmenus();
      initTags();
      initiInventories();

      // Initialize OCR Menu Import Drag-and-Drop
      try {
        initOCRMenuImportDnD();
      } catch (e) {
        console.warn('[OCR DnD] init failed', e);
      }
    } catch (e) {
      console.warn('[SmartMenu] Some initialization functions failed:', e);
    }

    // Initialize application manager
    await app.init();
  };

  await initializePageFunction();
  console.groupEnd();
};

// Add the event listener
document.addEventListener('turbo:load', turboLoadHandler);

// Also initialize OrderingModule when a Turbo Frame finishes loading and contains the dashboard
document.addEventListener('turbo:frame-load', (event) => {
  try {
    const frame = event.target;
    if (!(frame instanceof Element)) return;
    const el = frame.querySelector && frame.querySelector('#ordering-dashboard');
    if (el && window.OrderingModule && el.dataset.odInitialized !== 'true') {
      el.dataset.odInitialized = 'true';
      console.log('[SmartMenu] Initializing OrderingModule via turbo:frame-load');
      window.OrderingModule.init(document);
    }
  } catch (e) {
    console.warn('[SmartMenu] OrderingModule turbo:frame-load init failed', e);
  }
});

// Log when the script first loads
console.log('Application JavaScript loaded. Waiting for turbo:load events...');
console.log('[SmartMenu] Application script loaded');
console.log('[SmartMenu] Current URL:', window.location.href);
console.log('[SmartMenu] Bootstrap available:', typeof window.bootstrap !== 'undefined');
console.log('[SmartMenu] jQuery available:', typeof window.$ !== 'undefined');

// Final safety: on full window load, initialize OrderingModule if ordering dashboard exists
window.addEventListener('load', () => {
  try {
    const odRoot = document.querySelector('#ordering-dashboard');
    if (odRoot && window.OrderingModule && odRoot.dataset.odInitialized !== 'true') {
      odRoot.dataset.odInitialized = 'true';
      console.log('[SmartMenu] Initializing OrderingModule via window load');
      window.OrderingModule.init(document);
    }
    // Retry once shortly after load in case of late DOM injections
    setTimeout(() => {
      const el = document.querySelector('#ordering-dashboard');
      if (el && window.OrderingModule && el.dataset.odInitialized !== 'true') {
        el.dataset.odInitialized = 'true';
        console.log('[SmartMenu] Initializing OrderingModule via post-load retry');
        try { window.OrderingModule.init(document); } catch (e) { console.warn('OrderingModule init retry failed', e); }
      }
    }, 250);

    // If we're on the ordering section URL, poll briefly for the dashboard then init once
    const isOrderingPage = /[?&]section=ordering\b/.test(window.location.search);
    if (isOrderingPage) {
      let tries = 0;
      const max = 30; // ~3s at 100ms
      const iv = setInterval(() => {
        tries++;
        const el = document.querySelector('#ordering-dashboard');
        if (el && window.OrderingModule && el.dataset.odInitialized !== 'true') {
          el.dataset.odInitialized = 'true';
          console.log('[SmartMenu] Initializing OrderingModule via ordering-page poll');
          try { window.OrderingModule.init(document); } catch (e) { console.warn('OrderingModule init poll failed', e); }
          clearInterval(iv);
        } else if (tries >= max) {
          clearInterval(iv);
        }
      }, 100);
    }
  } catch (e) {
    console.warn('[SmartMenu] OrderingModule window-load init failed', e);
  }
});
