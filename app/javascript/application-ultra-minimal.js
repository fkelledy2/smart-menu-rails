// Ultra-minimal core application - maximum bundle size reduction
// Target: 70%+ reduction by using native APIs and minimal dependencies

// Essential framework imports only
import '@hotwired/turbo-rails';
import { Application } from '@hotwired/stimulus';

// PWA functionality
import './pwa/pwa-manager.js';

// Minimal Bootstrap components (only what's absolutely necessary)
import 'bootstrap/js/dist/collapse';
import 'bootstrap/js/dist/dropdown';

// Native alternatives to heavy libraries
const NativeUtils = {
  // Native fetch-based utilities (replaces jQuery AJAX)
  async patch(url, body) {
    return fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: JSON.stringify(body),
    });
  },

  async del(url) {
    return fetch(url, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
    });
  },

  // Native DOM manipulation (replaces jQuery DOM methods)
  $(selector) {
    const elements = document.querySelectorAll(selector);
    return {
      length: elements.length,
      each(callback) {
        elements.forEach(callback);
      },
      on(event, handler) {
        elements.forEach((el) => el.addEventListener(event, handler));
      },
      addClass(className) {
        elements.forEach((el) => el.classList.add(className));
      },
      removeClass(className) {
        elements.forEach((el) => el.classList.remove(className));
      },
      toggleClass(className) {
        elements.forEach((el) => el.classList.toggle(className));
      },
      hide() {
        elements.forEach((el) => (el.style.display = 'none'));
      },
      show() {
        elements.forEach((el) => (el.style.display = ''));
      },
      val(value) {
        if (value !== undefined) {
          elements.forEach((el) => (el.value = value));
        }
        return elements[0]?.value;
      },
      text(text) {
        if (text !== undefined) {
          elements.forEach((el) => (el.textContent = text));
        }
        return elements[0]?.textContent;
      },
      html(html) {
        if (html !== undefined) {
          elements.forEach((el) => (el.innerHTML = html));
        }
        return elements[0]?.innerHTML;
      },
    };
  },

  // Native date formatting (replaces Luxon for basic cases)
  formatDate(date, format = 'short') {
    const d = new Date(date);
    switch (format) {
      case 'short':
        return d.toLocaleDateString();
      case 'long':
        return d.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
        });
      case 'time':
        return d.toLocaleTimeString();
      case 'datetime':
        return d.toLocaleString();
      default:
        return d.toLocaleDateString();
    }
  },

  // Native table functionality (basic alternative to Tabulator)
  createSimpleTable(container, data, columns) {
    const table = document.createElement('table');
    table.className = 'table table-striped';

    // Create header
    const thead = document.createElement('thead');
    const headerRow = document.createElement('tr');
    columns.forEach((col) => {
      const th = document.createElement('th');
      th.textContent = col.title;
      headerRow.appendChild(th);
    });
    thead.appendChild(headerRow);
    table.appendChild(thead);

    // Create body
    const tbody = document.createElement('tbody');
    data.forEach((row) => {
      const tr = document.createElement('tr');
      columns.forEach((col) => {
        const td = document.createElement('td');
        td.textContent = row[col.field] || '';
        tr.appendChild(td);
      });
      tbody.appendChild(tr);
    });
    table.appendChild(tbody);

    container.appendChild(table);
    return table;
  },

  // Native select enhancement (basic alternative to TomSelect)
  enhanceSelect(selectElement) {
    // Add search functionality for large selects
    if (selectElement.options.length > 10) {
      const wrapper = document.createElement('div');
      wrapper.className = 'select-wrapper';

      const searchInput = document.createElement('input');
      searchInput.type = 'text';
      searchInput.placeholder = 'Search...';
      searchInput.className = 'form-control mb-2';

      selectElement.parentNode.insertBefore(wrapper, selectElement);
      wrapper.appendChild(searchInput);
      wrapper.appendChild(selectElement);

      searchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        Array.from(selectElement.options).forEach((option) => {
          const text = option.textContent.toLowerCase();
          option.style.display = text.includes(searchTerm) ? '' : 'none';
        });
      });
    }
  },
};

// Ultra-lightweight module loader
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
          // Only load full Tabulator if complex tables are needed
          if (document.querySelector('[data-tabulator-complex]')) {
            module = await import('tabulator-tables');
            window.Tabulator = module.TabulatorFull;
          } else {
            // Use native table for simple cases
            window.Tabulator = { create: NativeUtils.createSimpleTable };
          }
          break;
        case 'tomselect':
          // Only load TomSelect for complex selects
          if (document.querySelector('[data-tomselect-complex]')) {
            module = await import('tom-select');
            window.TomSelect = module.default;
          } else {
            // Use native enhancement for simple cases
            document.querySelectorAll('select[data-tomselect]').forEach((select) => {
              NativeUtils.enhanceSelect(select);
            });
          }
          break;
        case 'jquery':
          // Provide native alternative instead of loading jQuery
          window.$ = window.jQuery = NativeUtils.$;
          console.log('[SmartMenu] Using native jQuery alternative');
          break;
        case 'charts':
          // Only load Chart.js when actually needed
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

// Global utilities with native alternatives
window.SmartMenu = {
  loadModule: moduleLoader.load.bind(moduleLoader),
  patch: NativeUtils.patch,
  del: NativeUtils.del,
  formatDate: NativeUtils.formatDate,
  $: NativeUtils.$,
};

// Make native utilities available globally
window.$ = window.jQuery = NativeUtils.$;
window.patch = NativeUtils.patch;
window.del = NativeUtils.del;

// Auto-detect and conditionally load libraries
const autoLoadLibraries = async () => {
  // Only load heavy libraries when complex features are detected
  if (document.querySelector('[data-tabulator-complex]')) {
    await window.SmartMenu.loadModule('tabulator');
  }

  if (document.querySelector('[data-tomselect-complex]')) {
    await window.SmartMenu.loadModule('tomselect');
  } else if (document.querySelector('select[data-tomselect]')) {
    // Use native enhancement for simple selects
    document.querySelectorAll('select[data-tomselect]').forEach((select) => {
      NativeUtils.enhanceSelect(select);
    });
  }

  if (document.querySelector('[data-chart], canvas[data-chart-type]')) {
    await window.SmartMenu.loadModule('charts');
  }

  // Initialize simple tables with native functionality
  document.querySelectorAll('[data-simple-table]').forEach((container) => {
    const data = JSON.parse(container.dataset.tableData || '[]');
    const columns = JSON.parse(container.dataset.tableColumns || '[]');
    if (data.length && columns.length) {
      NativeUtils.createSimpleTable(container, data, columns);
    }
  });
};

// Initialize page functionality
const initializePage = async () => {
  await autoLoadLibraries();

  // Initialize page-specific modules
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
  console.log('[SmartMenu] Ultra-minimal page loaded');
  await initializePage();
});

// Cleanup on navigation
document.addEventListener('turbo:before-cache', () => {
  document.querySelectorAll('.tooltip, .popover').forEach((el) => el.remove());

  // Cleanup enhanced selects
  document.querySelectorAll('.select-wrapper input').forEach((input) => {
    input.removeEventListener('input', input._searchHandler);
  });
});

console.log('[SmartMenu] Ultra-minimal core loaded - maximum optimization achieved');
