import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { INVENTORY_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch } from '../../utils/api.js';

/**
 * Inventory module - handles all inventory-related functionality
 * Replaces the monolithic inventories.js file (118 lines → ~140 lines with better structure)
 */
export class InventoryModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
  }

  /**
   * Initialize the inventory module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeForms();
    this.initializeTables();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, { 
      component: 'InventoryModule', 
      instance: this 
    });

    return this;
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('inventory');
    
    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Inventory details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;
      
      // Special handling for menu item select
      if (element.id === 'inventory_menuitem_id') {
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

    // Initialize inventory table
    const inventoryTable = this.find('#menusection-inventory-table');
    if (inventoryTable) {
      // Get restaurant ID from data attribute
      const restaurantId = inventoryTable.getAttribute('data-bs-restaurant');
      
      const table = this.tableManager.initializeTable(inventoryTable, {
        ajaxURL: `/restaurants/${restaurantId}/inventories.json`,
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
            visible: true, 
            formatter: "rownum", 
            hozAlign: "right", 
            headerHozAlign: "right", 
            headerSort: false 
          },
          {
            title: "Item", 
            field: "id", 
            responsive: 0, 
            maxWidth: 180, 
            formatter: this.linkFormatter, 
            hozAlign: "left"
          },
          {
            title: "Inventory", 
            field: "inventory", 
            responsive: 0, 
            hozAlign: "right", 
            headerHozAlign: "right", 
            mutator: this.inventoryMutator
          },
          {
            title: "Resets At", 
            field: "resethour", 
            responsive: 3, 
            hozAlign: "right", 
            headerHozAlign: "right"
          },
          {
            title: "Status", 
            field: "status", 
            formatter: this.statusFormatter, 
            responsive: 3, 
            minWidth: 100, 
            hozAlign: "right", 
            headerHozAlign: "right"
          }
        ],
        locale: true,
        langs: {
          "it": {
            "columns": {
              "id": "Articolo",
              "inventory": "inventario",
              "resethour": "Si ripristina a",
              "status": "Stato"
            }
          },
          "en": {
            "columns": {
              "id": "Item",
              "inventory": "Inventory",
              "resethour": "Resets At",
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
      const actionsBtn = this.find('#inventory-actions');
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
          inventory: { sequence: newSequence }
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
    const name = rowData?.menuitem?.name || id;
    return `<a class='link-dark' href='/inventories/${id}/edit'>${name}</a>`;
  }

  /**
   * Inventory mutator - formats current/starting inventory display
   */
  inventoryMutator(value, data) {
    const current = data.currentinventory || 0;
    const starting = data.startinginventory || 0;
    return `${current}/${starting}`;
  }

  /**
   * Update related data when menu item changes
   */
  updateRelatedData(menuitemId) {
    EventBus.emit(AppEvents.MENUITEM_SELECT, { 
      menuitem: { id: menuitemId } 
    });

    // Update any dependent data
    this.refreshInventoryTable();
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
    const inventoryForms = this.findAll('form[data-inventory-form]');
    inventoryForms.forEach(form => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Listen for global menu item events
    EventBus.on(AppEvents.MENUITEM_SELECT, (event) => {
      const { menuitem } = event.detail;
      this.onMenuItemSelected(menuitem);
    });
  }

  /**
   * Bind bulk action buttons
   */
  bindBulkActions() {
    const activateBtn = this.find('#activate-inventory');
    const deactivateBtn = this.find('#deactivate-inventory');
    const resetBtn = this.find('#reset-inventory');
    
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

    if (resetBtn) {
      this.addEventListener(resetBtn, 'click', () => {
        this.bulkResetInventory();
      });
    }
  }

  /**
   * Bulk update status for selected rows
   */
  async bulkUpdateStatus(status) {
    const table = this.tableManager.getTable('#menusection-inventory-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();
    
    for (const rowData of selectedRows) {
      try {
        // Update table data
        table.updateData([{ id: rowData.id, status: status }]);
        
        // Update server
        await patch(rowData.url, {
          inventory: { status: status }
        });
      } catch (error) {
        console.error('Failed to update status:', error);
        this.showNotification(`Failed to update inventory status`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(`Updated ${selectedRows.length} inventory item(s) to ${status}`, 'success');
    }
  }

  /**
   * Bulk reset inventory for selected rows
   */
  async bulkResetInventory() {
    const table = this.tableManager.getTable('#menusection-inventory-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();
    
    for (const rowData of selectedRows) {
      try {
        const resetValue = rowData.startinginventory;
        
        // Update table data
        table.updateData([{ 
          id: rowData.id, 
          currentinventory: resetValue 
        }]);
        
        // Update server
        await patch(rowData.url, {
          inventory: { currentinventory: resetValue }
        });
      } catch (error) {
        console.error('Failed to reset inventory:', error);
        this.showNotification(`Failed to reset inventory`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(`Reset ${selectedRows.length} inventory item(s)`, 'success');
    }
  }

  /**
   * Handle menu item selection
   */
  onMenuItemSelected(menuitem) {
    // Update any UI elements that depend on menu item selection
    const itemNameElements = this.findAll('.current-item-name');
    itemNameElements.forEach(el => {
      el.textContent = menuitem.name;
    });
  }

  /**
   * Refresh inventory table
   */
  refreshInventoryTable() {
    this.tableManager.refreshTable('#menusection-inventory-table');
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
        this.showNotification('Inventory saved successfully', 'success');
        
        // Refresh tables if needed
        this.refreshInventoryTable();
        
        EventBus.emit(AppEvents.DATA_SAVE, { 
          type: 'inventory', 
          form: form 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save inventory', 'error');
    }
  }

  /**
   * Refresh all inventory data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.refreshInventoryTable();
    
    // Refresh forms
    this.formManager.refresh();
  }

  /**
   * Clean up inventory module
   */
  destroy() {
    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, { 
      component: 'InventoryModule' 
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new InventoryModule(container);
    return module.init();
  }
}
