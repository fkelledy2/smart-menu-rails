import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { MENUITEM_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch } from '../../utils/api.js';

/**
 * MenuItem module - handles all menu item-related functionality
 * Replaces the monolithic menuitems.js file (155 lines → ~180 lines with better structure)
 */
export class MenuItemModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
    this.restaurantCurrencySymbol = '$';
  }

  /**
   * Initialize the menu item module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeCurrency();
    this.initializeForms();
    this.initializeTables();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, { 
      component: 'MenuItemModule', 
      instance: this 
    });

    return this;
  }

  /**
   * Initialize currency symbol from restaurant data
   */
  initializeCurrency() {
    const currencyElement = this.find('#restaurantCurrency');
    if (currencyElement) {
      this.restaurantCurrencySymbol = currencyElement.textContent.trim() || '$';
    }
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('menuitem');
    
    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Menu item details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;
      
      // Special handling for menu section select
      if (element.id === 'menuitem_menusection_id') {
        tomSelect.on('change', (value) => {
          this.updateRelatedData(value);
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

    // Initialize menu section menu item table
    const menuItemTable = this.find('#menusection-menuitem-table');
    if (menuItemTable) {
      const menusectionId = menuItemTable.dataset.menusection;
      const menuId = menuItemTable.dataset.menu;
      if (menusectionId && menuId) {
        const restaurantId = this.getRestaurantId();
        const ajaxURL = restaurantId ? 
          `/restaurants/${restaurantId}/menus/${menuId}/menusections/${menusectionId}/menuitems.json` :
          `/menus/${menuId}/menusections/${menusectionId}/menuitems.json`;
        
        const table = this.tableManager.initializeTable(menuItemTable, {
          ajaxURL: ajaxURL,
          movableRows: true,
          initialSort: [{ column: "sequence", dir: "asc" }],
          columns: [
            {
              formatter: "rowSelection", 
              titleFormatter: "rowSelection", 
              responsive: 0, 
              width: 30, 
              frozen: true, 
              headerHozAlign: "left", 
              hozAlign: "left", 
              headerSort: false,
              cellClick: (e, cell) => cell.getRow().toggleSelect()
            },
            { 
              rowHandle: true, 
              formatter: "handle", 
              headerSort: false, 
              frozen: true, 
              responsive: 0, 
              width: 30, 
              minWidth: 30 
            },
            { 
              title: "", 
              field: "sequence", 
              visible: false, 
              formatter: "rownum", 
              hozAlign: "right", 
              headerHozAlign: "right", 
              headerSort: false 
            },
            {
              title: "Name", 
              field: "id", 
              responsive: 0, 
              maxWidth: 180, 
              formatter: this.linkFormatter, 
              hozAlign: "left"
            },
            {
              title: "genImageId", 
              visible: false, 
              field: "genImageId"
            },
            {
              title: "Calories", 
              field: "calories", 
              responsive: 5, 
              hozAlign: "right", 
              headerHozAlign: "right"
            },
            {
              title: "Price", 
              field: "price", 
              responsive: 4, 
              formatter: "money", 
              hozAlign: "right", 
              headerHozAlign: "right",
              formatterParams: {
                decimal: ".",
                thousand: ",",
                symbol: this.restaurantCurrencySymbol,
                negativeSign: true,
                precision: 2
              }
            },
            {
              title: "Prep Time", 
              field: "preptime", 
              responsive: 5, 
              hozAlign: "right", 
              headerHozAlign: "right"
            },
            {
              title: "Inventory",
              columns: [
                {
                  title: "Starting", 
                  responsive: 5, 
                  field: "inventory.startinginventory", 
                  hozAlign: "right", 
                  headerHozAlign: "right"
                },
                {
                  title: "Current", 
                  responsive: 5, 
                  field: "inventory.currentinventory", 
                  hozAlign: "right", 
                  headerHozAlign: "right"
                },
                {
                  title: "Resets At", 
                  responsive: 5, 
                  field: "inventory.resethour", 
                  hozAlign: "right", 
                  headerHozAlign: "right"
                }
              ]
            },
            {
              title: "Status", 
              field: "status", 
              formatter: this.statusFormatter, 
              responsive: 0, 
              minWidth: 100, 
              hozAlign: "right", 
              headerHozAlign: "right"
            }
          ],
          locale: true,
          langs: {
            "it": {
              "columns": {
                "id": "Nome",
                "status": "Stato"
              }
            },
            "en": {
              "columns": {
                "id": "Name",
                "status": "Status"
              }
            }
          }
        });

        if (table) {
          this.setupTableEvents(table);
        }
      }
    }
  }

  /**
   * Set up table events
   */
  setupTableEvents(table) {
    // Row moved event
    table.on("rowMoved", (row) => {
      this.updateSequences(table);
    });

    // Row selection changed
    table.on("rowSelectionChanged", (data, rows) => {
      const actionsBtn = this.find('#menuitem-actions');
      if (actionsBtn) {
        actionsBtn.disabled = data.length === 0;
      }
    });
  }

  /**
   * Update sequences after row move
   */
  async updateSequences(table) {
    const rows = table.getRows();
    
    for (let i = 0; i < rows.length; i++) {
      const rowData = rows[i].getData();
      const newSequence = rows[i].getPosition();
      
      // Update table data
      table.updateData([{ id: rowData.id, sequence: newSequence }]);
      
      // Update server
      try {
        await patch(rowData.url, {
          menuitem: { sequence: newSequence }
        });
      } catch (error) {
        console.error('Failed to update sequence:', error);
        this.showNotification('Failed to update order', 'error');
      }
    }
  }

  /**
   * Status formatter for tables
   */
  statusFormatter(cell) {
    const status = cell.getRow().getData("data")?.status || cell.getValue();
    return status ? status.toUpperCase() : '';
  }

  /**
   * Link formatter for tables
   */
  linkFormatter(cell) {
    const id = cell.getValue();
    const rowData = cell.getRow().getData("data");
    const name = rowData?.name || id;
    
    // Get menu and menusection IDs from table element for nested routes
    const tableElement = cell.getTable().element;
    const menuId = tableElement.dataset.menu || tableElement.dataset.bsMenu;
    const menusectionId = tableElement.dataset.menusection || tableElement.dataset.bsMenusection;
    
    const restaurantId = this.getRestaurantId();
    
    if (restaurantId && menuId && menusectionId) {
      return `<a class='link-dark' href='/restaurants/${restaurantId}/menus/${menuId}/menusections/${menusectionId}/menuitems/${id}/edit'>${name}</a>`;
    } else if (menuId && menusectionId) {
      return `<a class='link-dark' href='/menus/${menuId}/menusections/${menusectionId}/menuitems/${id}/edit'>${name}</a>`;
    } else {
      // Fallback to old route if context not available
      return `<a class='link-dark' href='/menuitems/${id}/edit'>${name}</a>`;
    }
  }

  /**
   * Update related data when menu section changes
   */
  updateRelatedData(menusectionId) {
    EventBus.emit(AppEvents.MENUSECTION_SELECT, { 
      menusection: { id: menusectionId } 
    });

    // Update any dependent tables
    const menuItemTable = this.tableManager.getTable('#menusection-menuitem-table');
    if (menuItemTable) {
      const newUrl = `/menusections/${menusectionId}/menuitems.json`;
      menuItemTable.setData(newUrl);
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
    // Handle bulk actions
    this.bindBulkActions();

    // Handle form submissions
    const menuItemForms = this.findAll('form[data-menuitem-form]');
    menuItemForms.forEach(form => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Listen for global menu section events
    EventBus.on(AppEvents.MENUSECTION_SELECT, (event) => {
      const { menusection } = event.detail;
      this.onMenuSectionSelected(menusection);
    });

    // Handle price changes for currency updates
    EventBus.on('currency:changed', (event) => {
      const { symbol } = event.detail;
      this.updateCurrencySymbol(symbol);
    });
  }

  /**
   * Bind bulk action buttons
   */
  bindBulkActions() {
    const genImageBtn = this.find('#genimage-menuitem');
    const activateBtn = this.find('#activate-menuitem');
    const deactivateBtn = this.find('#deactivate-menuitem');
    
    if (genImageBtn) {
      this.addEventListener(genImageBtn, 'click', () => {
        this.bulkGenerateImages();
      });
    }
    
    if (activateBtn) {
      this.addEventListener(activateBtn, 'click', () => {
        this.bulkUpdateStatus('active');
      });
    }
    
    if (deactivateBtn) {
      this.addEventListener(deactivateBtn, 'click', () => {
        this.bulkUpdateStatus('inactive');
      });
    }
  }

  /**
   * Bulk generate images for selected menu items
   */
  async bulkGenerateImages() {
    const table = this.tableManager.getTable('#menusection-menuitem-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();
    let successCount = 0;
    
    for (const rowData of selectedRows) {
      if (rowData.genImageId) {
        try {
          await patch(`/genimages/${rowData.genImageId}`, {
            genimage: { id: rowData.genImageId }
          });
          successCount++;
        } catch (error) {
          console.error('Failed to generate image:', error);
        }
      }
    }

    if (successCount > 0) {
      this.showNotification(`Started image generation for ${successCount} menu item(s)`, 'success');
    } else {
      this.showNotification('No images could be generated', 'warning');
    }
  }

  /**
   * Bulk update status for selected rows
   */
  async bulkUpdateStatus(status) {
    const table = this.tableManager.getTable('#menusection-menuitem-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();
    
    for (const rowData of selectedRows) {
      try {
        // Update table data
        table.updateData([{ id: rowData.id, status: status }]);
        
        // Update server
        await patch(rowData.url, {
          menuitem: { status: status }
        });
      } catch (error) {
        console.error('Failed to update status:', error);
        this.showNotification(`Failed to update menu item status`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(`Updated ${selectedRows.length} menu item(s) to ${status}`, 'success');
    }
  }

  /**
   * Handle menu section selection
   */
  onMenuSectionSelected(menusection) {
    // Update any UI elements that depend on menu section selection
    const sectionNameElements = this.findAll('.current-section-name');
    sectionNameElements.forEach(el => {
      el.textContent = menusection.name;
    });

    // Update breadcrumbs
    const breadcrumbElements = this.findAll('.section-breadcrumb');
    breadcrumbElements.forEach(el => {
      el.textContent = menusection.name;
      el.href = `/menusections/${menusection.id}`;
    });
  }

  /**
   * Update currency symbol in price formatters
   */
  updateCurrencySymbol(newSymbol) {
    this.restaurantCurrencySymbol = newSymbol;
    
    // Update existing tables
    const table = this.tableManager.getTable('#menusection-menuitem-table');
    if (table) {
      // Update the price column formatter
      const priceColumn = table.getColumn('price');
      if (priceColumn) {
        priceColumn.updateDefinition({
          formatterParams: {
            decimal: ".",
            thousand: ",",
            symbol: newSymbol,
            negativeSign: true,
            precision: 2
          }
        });
        table.redraw();
      }
    }
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
        this.showNotification('Menu item saved successfully', 'success');
        
        // Refresh tables if needed
        this.tableManager.refreshTable('#menusection-menuitem-table');
        
        EventBus.emit(AppEvents.DATA_SAVE, { 
          type: 'menuitem', 
          form: form 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save menu item', 'error');
    }
  }

  /**
   * Refresh all menu item data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.tableManager.refreshTable('#menusection-menuitem-table');
    
    // Refresh forms
    this.formManager.refresh();
    
    // Update currency symbol
    this.initializeCurrency();
  }

  /**
   * Get restaurant ID using smart detection system
   */
  getRestaurantId() {
    // Use the enhanced restaurant context system if available
    if (window.RestaurantContext) {
      return window.RestaurantContext.getRestaurantId(this.container);
    }
    
    // Fallback to basic detection for backward compatibility
    const pathMatch = window.location.pathname.match(/\/restaurants\/(\d+)/);
    if (pathMatch) {
      return pathMatch[1];
    }
    
    const restaurantElement = this.find('[data-restaurant-id]');
    if (restaurantElement) {
      return restaurantElement.dataset.restaurantId;
    }
    
    if (window.currentRestaurant) {
      return window.currentRestaurant.id;
    }
    
    return null;
  }

  /**
   * Clean up menu item module
   */
  destroy() {
    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, { 
      component: 'MenuItemModule' 
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new MenuItemModule(container);
    return module.init();
  }
}
