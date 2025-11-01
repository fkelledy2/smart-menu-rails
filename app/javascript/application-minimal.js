// Minimal core application - only essential functionality
// Target: Maximum bundle size reduction while maintaining functionality

// Essential framework imports only
import '@hotwired/turbo-rails';
import { Application } from '@hotwired/stimulus';

// Minimal Bootstrap components (only what's absolutely necessary)
import 'bootstrap/js/dist/collapse';
import 'bootstrap/js/dist/dropdown';

// Essential utilities
const moduleLoader = {
  loadedModules: new Map(),

  async load(moduleName) {
    if (this.loadedModules.has(moduleName)) {
      return this.loadedModules.get(moduleName);
    }

    try {
      let module;
      switch (moduleName) {
        case 'tabulator':
          module = await import('tabulator-tables');
          window.Tabulator = module.TabulatorFull;
          break;
        case 'tomselect':
          module = await import('tom-select');
          window.TomSelect = module.default;
          break;
        case 'jquery':
          module = await import('jquery');
          window.$ = window.jQuery = module.default;
          break;
        case 'charts':
          module = await import('chart.js/auto');
          window.Chart = module.Chart;
          break;
        default:
          console.warn(`Unknown module: ${moduleName}`);
          return null;
      }

      this.loadedModules.set(moduleName, module);
      console.log(`[SmartMenu] Loaded ${moduleName}`);
      return module;
    } catch (error) {
      console.error(`Failed to load ${moduleName}:`, error);
      return null;
    }
  },
};

// Initialize Stimulus
const application = Application.start();
window.Stimulus = application;

// Global utilities
window.SmartMenu = {
  loadModule: moduleLoader.load.bind(moduleLoader),

  // Essential utility functions
  patch: async (url, body) => {
    return fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: JSON.stringify(body),
    });
  },

  del: async (url) => {
    return fetch(url, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
    });
  },
};

// Auto-detect and load required libraries based on page content
const autoLoadLibraries = async () => {
  // Load Tabulator only if tables are present
  if (document.querySelector('[data-tabulator], .tabulator')) {
    await window.SmartMenu.loadModule('tabulator');
  }

  // Load TomSelect only if select elements need enhancement
  if (document.querySelector('[data-tomselect], .tomselect')) {
    await window.SmartMenu.loadModule('tomselect');
  }

  // Load jQuery only if explicitly needed
  if (document.querySelector('[data-jquery-required]')) {
    await window.SmartMenu.loadModule('jquery');
  }

  // Load Chart.js only if charts are present
  if (document.querySelector('[data-chart], canvas[data-chart-type]')) {
    await window.SmartMenu.loadModule('charts');
  }
};

// Initialize page-specific functionality
const initializePage = async () => {
  // Auto-load required libraries
  await autoLoadLibraries();

  // Initialize page-specific modules based on data attributes
  const pageModules = document.body.dataset.modules?.split(',') || [];

  for (const moduleName of pageModules) {
    try {
      const trimmedName = moduleName.trim();
      if (trimmedName) {
        await window.SmartMenu.loadModule(trimmedName);
      }
    } catch (error) {
      console.warn(`Failed to load module ${moduleName}:`, error);
    }
  }

  // Initialize legacy functionality if needed
  if (typeof window.initLegacyFunctions === 'function') {
    window.initLegacyFunctions();
  }
};

// Turbo event handling
document.addEventListener('turbo:load', async () => {
  console.log('[SmartMenu] Page loaded');
  await initializePage();
});

// Cleanup on navigation
document.addEventListener('turbo:before-cache', () => {
  // Cleanup tooltips and popovers
  document.querySelectorAll('.tooltip, .popover').forEach((el) => el.remove());

  // Cleanup TomSelect instances
  document.querySelectorAll('[data-tom-select-initialized="true"]').forEach((element) => {
    if (element.tomSelect && typeof element.tomSelect.destroy === 'function') {
      try {
        element.tomSelect.destroy();
        element.removeAttribute('data-tom-select-initialized');
        delete element.tomSelect;
      } catch (error) {
        console.warn('Failed to cleanup TomSelect:', error);
      }
    }
  });
});

console.log('[SmartMenu] Minimal core loaded');
