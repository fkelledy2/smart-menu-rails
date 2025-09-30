import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { RESTAURANT_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';

/**
 * Restaurant module - handles all restaurant-related functionality
 * Replaces the monolithic restaurants.js file
 */
export class RestaurantModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
    this.qrCodes = new Map();
  }

  /**
   * Initialize the restaurant module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeForms();
    this.initializeTables();
    this.initializeQRCodes();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, { 
      component: 'RestaurantModule', 
      instance: this 
    });

    return this;
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('restaurant');
    
    // Initialize form manager for restaurant forms
    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Restaurant details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;
      
      // Special handling for country/currency selects
      if (element.id === 'restaurant_country') {
        tomSelect.on('change', (value) => {
          this.updateCurrencyOptions(value);
        });
      }
    });
  }

  /**
   * Initialize table management
   */
  initializeTables() {
    this.tableManager = new TableManager(this.container);
    this.addChildComponent('tableManager', this.tableManager);
    this.tableManager.init();

    // Initialize restaurant listing table
    const restaurantTable = this.find('#restaurant-table');
    if (restaurantTable) {
      const table = this.tableManager.initializeTable(restaurantTable, RESTAURANT_TABLE_CONFIG);
      
      if (table) {
        // Set up table event listeners
        this.tableManager.on('table:row:click', (event) => {
          const { data } = event.detail;
          this.handleRestaurantSelect(data);
        });

        this.tableManager.on('table:data:loaded', (event) => {
          this.updateTableStats(event.detail.data);
        });
      }
    }

    // Initialize related tables (menus, employees, etc.)
    this.initializeRelatedTables();
  }

  /**
   * Initialize related entity tables
   */
  initializeRelatedTables() {
    const relatedTables = [
      { selector: '#restaurant-menu-table', type: 'menu' },
      { selector: '#restaurant-employee-table', type: 'employee' },
      { selector: '#restaurant-tracks-table', type: 'track' },
      { selector: '#restaurant-locale-table', type: 'locale' },
      { selector: '#restaurant-openinghour-table', type: 'availability' },
      { selector: '#restaurant-tablesetting-table', type: 'tablesetting' }
    ];

    relatedTables.forEach(({ selector, type }) => {
      const tableElement = this.find(selector);
      if (tableElement) {
        const restaurantId = tableElement.dataset.restaurantId;
        if (restaurantId) {
          this.tableManager.initializeTable(tableElement, {
            ajaxURL: `${selector.replace('#restaurant-', '/restaurants/' + restaurantId + '/')}.json`
          });
        }
      }
    });
  }

  /**
   * Initialize QR code generation
   */
  initializeQRCodes() {
    const qrElements = this.findAll('.qrSlug');
    
    qrElements.forEach(element => {
      this.generateQRCode(element);
    });
  }

  /**
   * Generate QR code for a restaurant
   */
  generateQRCode(element) {
    const qrSlug = element.textContent.trim();
    const qrHost = this.find('#qrHost')?.textContent || window.location.host;
    const qrIcon = this.find('#qrIcon')?.textContent || '';

    if (!qrSlug) return;

    try {
      const qrCode = new QRCodeStyling({
        type: "canvas",
        shape: "square",
        width: 300,
        height: 300,
        data: `https://${qrHost}/smartmenus/${qrSlug}`,
        margin: 0,
        qrOptions: {
          typeNumber: "0",
          mode: "Byte",
          errorCorrectionLevel: "Q"
        },
        imageOptions: {
          saveAsBlob: true,
          hideBackgroundDots: true,
          imageSize: 0.4,
          margin: 0
        },
        dotsOptions: {
          type: "extra-rounded",
          color: "#000000",
          roundSize: true
        },
        backgroundOptions: {
          round: 0,
          color: "#ffffff"
        },
        image: qrIcon,
        dotsOptionsHelper: {
          colorType: {
            single: true,
            gradient: false
          },
          gradient: {
            linear: true,
            radial: false,
            color1: "#6a1a4c",
            color2: "#6a1a4c",
            rotation: "0"
          }
        },
        cornersSquareOptions: {
          type: "extra-rounded",
          color: "#000000"
        },
        cornersDotOptions: {
          type: "extra-rounded",
          color: "#000000"
        }
      });

      // Store QR code instance
      this.qrCodes.set(qrSlug, qrCode);

      // Find container and append QR code
      const container = element.closest('.qr-container') || element.parentElement;
      if (container) {
        const qrContainer = document.createElement('div');
        qrContainer.className = 'qr-code-display mt-2';
        qrCode.append(qrContainer);
        container.appendChild(qrContainer);
      }

      EventBus.emit(AppEvents.DATA_LOAD, { 
        type: 'qr_code_generated', 
        slug: qrSlug 
      });

    } catch (error) {
      console.error('Failed to generate QR code:', error);
      this.showNotification('Failed to generate QR code', 'error');
    }
  }

  /**
   * Update currency options based on selected country
   */
  updateCurrencyOptions(countryCode) {
    const currencySelect = this.formManager.getSelect('#restaurant_currency');
    if (!currencySelect || !countryCode) return;

    // Country to currency mapping (simplified)
    const countryCurrencies = {
      'US': 'USD',
      'GB': 'GBP',
      'DE': 'EUR',
      'FR': 'EUR',
      'JP': 'JPY',
      'CA': 'CAD',
      'AU': 'AUD',
      'IE': 'EUR'
    };

    const suggestedCurrency = countryCurrencies[countryCode];
    if (suggestedCurrency) {
      currencySelect.setValue(suggestedCurrency);
    }
  }

  /**
   * Handle restaurant selection from table
   */
  handleRestaurantSelect(restaurantData) {
    EventBus.emit(AppEvents.RESTAURANT_SELECT, { 
      restaurant: restaurantData 
    });

    // Update any dependent components
    this.updateRelatedTables(restaurantData.id);
  }

  /**
   * Update related tables when restaurant changes
   */
  updateRelatedTables(restaurantId) {
    const relatedTableSelectors = [
      '#restaurant-menu-table',
      '#restaurant-employee-table',
      '#restaurant-tracks-table'
    ];

    relatedTableSelectors.forEach(selector => {
      const table = this.tableManager.getTable(selector);
      if (table) {
        // Update AJAX URL with new restaurant ID
        const newUrl = selector.replace('#restaurant-', `/restaurants/${restaurantId}/`) + '.json';
        table.setData(newUrl);
      }
    });
  }

  /**
   * Update table statistics display
   */
  updateTableStats(data) {
    const statsContainer = this.find('.table-stats');
    if (statsContainer && Array.isArray(data)) {
      const totalCount = data.length;
      const activeCount = data.filter(item => item.status === 'active').length;
      
      statsContainer.innerHTML = `
        <div class="row">
          <div class="col-md-6">
            <div class="stat-item">
              <span class="stat-label">Total Restaurants:</span>
              <span class="stat-value">${totalCount}</span>
            </div>
          </div>
          <div class="col-md-6">
            <div class="stat-item">
              <span class="stat-label">Active:</span>
              <span class="stat-value">${activeCount}</span>
            </div>
          </div>
        </div>
      `;
    }
  }

  /**
   * Show notification to user
   */
  showNotification(message, type = 'info') {
    EventBus.emit(`notify:${type}`, { message });
  }

  /**
   * Bind module-specific events
   */
  bindEvents() {
    // Listen for global restaurant events
    EventBus.on(AppEvents.RESTAURANT_SELECT, (event) => {
      const { restaurant } = event.detail;
      this.onRestaurantSelected(restaurant);
    });

    // Handle form submissions
    const restaurantForms = this.findAll('form[data-restaurant-form]');
    restaurantForms.forEach(form => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Handle QR code download buttons
    const qrDownloadButtons = this.findAll('.qr-download-btn');
    qrDownloadButtons.forEach(button => {
      this.addEventListener(button, 'click', (e) => {
        this.handleQRDownload(e);
      });
    });

    // Handle restaurant deletion
    const deleteButtons = this.findAll('.delete-restaurant-btn');
    deleteButtons.forEach(button => {
      this.addEventListener(button, 'click', (e) => {
        this.handleRestaurantDelete(e);
      });
    });
  }

  /**
   * Handle restaurant selection
   */
  onRestaurantSelected(restaurant) {
    // Update any UI elements that depend on restaurant selection
    const restaurantNameElements = this.findAll('.current-restaurant-name');
    restaurantNameElements.forEach(el => {
      el.textContent = restaurant.name;
    });

    // Update breadcrumbs
    const breadcrumbElements = this.findAll('.restaurant-breadcrumb');
    breadcrumbElements.forEach(el => {
      el.textContent = restaurant.name;
      el.href = `/restaurants/${restaurant.id}`;
    });
  }

  /**
   * Handle form submission
   */
  async handleFormSubmit(event, form) {
    event.preventDefault();

    try {
      const formData = new FormData(form);
      const response = await fetch(form.action, {
        method: form.method || 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
        }
      });

      if (response.ok) {
        this.showNotification('Restaurant saved successfully', 'success');
        
        // Refresh tables if needed
        this.tableManager.refreshTable('#restaurant-table');
        
        EventBus.emit(AppEvents.DATA_SAVE, { 
          type: 'restaurant', 
          form: form 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save restaurant', 'error');
    }
  }

  /**
   * Handle QR code download
   */
  handleQRDownload(event) {
    const button = event.target;
    const qrSlug = button.dataset.qrSlug;
    const qrCode = this.qrCodes.get(qrSlug);

    if (qrCode) {
      qrCode.download({
        name: `qr-code-${qrSlug}`,
        extension: "png"
      });

      EventBus.emit(AppEvents.FEATURE_USED, { 
        feature: 'qr_code_download', 
        slug: qrSlug 
      });
    }
  }

  /**
   * Handle restaurant deletion
   */
  async handleRestaurantDelete(event) {
    const button = event.target;
    const restaurantId = button.dataset.restaurantId;
    const restaurantName = button.dataset.restaurantName;

    if (!confirm(`Are you sure you want to delete "${restaurantName}"? This action cannot be undone.`)) {
      return;
    }

    try {
      const response = await fetch(`/restaurants/${restaurantId}`, {
        method: 'DELETE',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
        }
      });

      if (response.ok) {
        this.showNotification('Restaurant deleted successfully', 'success');
        this.tableManager.refreshTable('#restaurant-table');
        
        EventBus.emit(AppEvents.DATA_DELETE, { 
          type: 'restaurant', 
          id: restaurantId 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Delete error:', error);
      this.showNotification('Failed to delete restaurant', 'error');
    }
  }

  /**
   * Refresh all restaurant data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.tableManager.refreshTable('#restaurant-table');
    
    // Refresh forms
    this.formManager.refresh();
    
    // Regenerate QR codes if needed
    this.initializeQRCodes();
  }

  /**
   * Clean up restaurant module
   */
  destroy() {
    // Clear QR codes
    this.qrCodes.clear();

    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, { 
      component: 'RestaurantModule' 
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new RestaurantModule(container);
    return module.init();
  }
}
