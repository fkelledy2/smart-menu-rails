// Core application bundle - essential functionality only
// This bundle is loaded on every page and should be kept minimal

// Essential framework imports
import '@hotwired/turbo-rails';
import { Application } from '@hotwired/stimulus';

// Essential utilities only
import './utils/ModuleLoader.js';
import './utils/EventBus.js';

// Core styling and basic interactions
import 'bootstrap/js/dist/collapse';
import 'bootstrap/js/dist/dropdown';
import 'bootstrap/js/dist/modal';

// Initialize Stimulus
const application = Application.start();
window.Stimulus = application;

// Global utilities
window.SmartMenu = {
  loadModule: async (moduleName) => {
    const { ModuleLoader } = await import('./utils/ModuleLoader.js');
    return ModuleLoader.load(moduleName);
  },
};

// Essential page initialization
document.addEventListener('turbo:load', async () => {
  console.log('[SmartMenu] Core application loaded');

  // Auto-detect and load required modules based on page content
  const pageModules = document.body.dataset.modules?.split(',') || [];

  for (const moduleName of pageModules) {
    try {
      await window.SmartMenu.loadModule(moduleName.trim());
    } catch (error) {
      console.warn(`Failed to load module ${moduleName}:`, error);
    }
  }
});

console.log('[SmartMenu] Core bundle loaded');
