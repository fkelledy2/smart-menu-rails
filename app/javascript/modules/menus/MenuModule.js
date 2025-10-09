import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { MENU_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch } from '../../utils/api.js';

/**
 * Menu module - handles all menu-related functionality
 * Replaces the monolithic menus.js file (287 lines → ~200 lines)
 */
export class MenuModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
    this.activeTabStorage = 'activeMenuPillId';
  }

  /**
   * Initialize the menu module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeForms();
    this.initializeTables();
    this.initializeScrollSpy();
    this.initializeTabs();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, { 
      component: 'MenuModule', 
      instance: this 
    });

    return this;
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('menu');
    
    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Menu details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;
      
      // Special handling for restaurant select
      if (element.id === 'menu_restaurant_id') {
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

    // Initialize main menu table
    const menuTable = this.find('#menu-table');
    if (menuTable) {
      const table = this.tableManager.initializeTable(menuTable, {
        ...MENU_TABLE_CONFIG,
        movableRows: true,
        initialSort: [{ column: "sequence", dir: "asc" }],
        columns: [
          {
            formatter: "rowSelection", 
            titleFormatter: "rowSelection", 
            width: 30, 
            headerHozAlign: "center", 
            hozAlign: "center", 
            headerSort: false,
            cellClick: (e, cell) => cell.getRow().toggleSelect()
          },
          {
            title: "Restaurant", 
            field: "restaurant.id", 
            responsive: 0, 
            formatter: "link", 
            formatterParams: {
              labelField: "restaurant.name",
              urlPrefix: "/restaurants/"
            }
          },
          { 
            rowHandle: true, 
            formatter: "handle", 
            headerSort: false, 
            responsive: 0, 
            width: 30, 
            minWidth: 30 
          },
          { 
            title: "", 
            field: "sequence", 
            formatter: "rownum", 
            responsive: 5, 
            hozAlign: "right", 
            headerHozAlign: "right", 
            headerSort: false 
          },
          {
            title: "Name", 
            field: "id", 
            responsive: 0, 
            formatter: this.linkFormatter
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
        ]
      });

      if (table) {
        this.setupMainTableEvents(table);
      }
    }

    // Initialize restaurant menu table
    const restaurantMenuTable = this.find('#restaurant-menu-table');
    if (restaurantMenuTable) {
      const restaurantId = restaurantMenuTable.dataset.restaurantId;
      if (restaurantId) {
        const table = this.tableManager.initializeTable(restaurantMenuTable, {
          ajaxURL: `/restaurants/${restaurantId}/menus.json`,
          movableRows: true,
          initialSort: [{ column: "sequence", dir: "asc" }],
          columns: [
            {
              formatter: "rowSelection", 
              titleFormatter: "rowSelection", 
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
              responsive: 5, 
              hozAlign: "right", 
              headerHozAlign: "right", 
              headerSort: false 
            },
            {
              title: "Name", 
              field: "id", 
              formatter: this.linkFormatter, 
              hozAlign: "left"
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
          this.setupRestaurantTableEvents(table);
        }
      }
    }
  }

  /**
   * Initialize scroll spy functionality
   */
  initializeScrollSpy() {
    let scrollTimer;
    
    this.addEventListener(window, 'activate.bs.scrollspy', () => {
      clearTimeout(scrollTimer);
      scrollTimer = setTimeout(() => {
        const activeElement = this.find('.menu_sections_tab a.active');
        if (activeElement) {
          // Could add smooth scrolling behavior here if needed
          EventBus.emit('menu:section:activated', { element: activeElement });
        }
      }, 100);
    });

    // Handle section navigation clicks
    const sectionNavs = this.findAll('.sectionnav');
    sectionNavs.forEach(nav => {
      this.addEventListener(nav, 'click', (event) => {
        event.preventDefault();
        this.scrollToSection(nav.getAttribute('href'));
      });
    });
  }

  /**
   * Initialize tab functionality with persistence
   */
  initializeTabs() {
    const menuTabs = this.find('#menuTabs');
    if (menuTabs) {
      const pills = menuTabs.querySelectorAll('button[data-bs-toggle="tab"]');
      
      pills.forEach(pill => {
        this.addEventListener(pill, 'shown.bs.tab', (event) => {
          const { target } = event;
          const { id: targetId } = target;
          this.saveActiveTab(targetId);
        });
      });

      // Restore active tab on load
      this.restoreActiveTab();
    }
  }

  /**
   * Scroll to a specific section
   */
  scrollToSection(href) {
    const target = this.find(href);
    if (!target) return;

    const menuHeader = this.find('#menuu') || this.find('#menuc');
    const offset = menuHeader ? menuHeader.offsetHeight : 0;

    const targetPosition = target.offsetTop - offset;
    
    window.scrollTo({
      top: targetPosition,
      behavior: 'smooth'
    });
  }

  /**
   * Save active tab to localStorage
   */
  saveActiveTab(tabId) {
    localStorage.setItem(this.activeTabStorage, tabId);
  }

  /**
   * Restore active tab from localStorage
   */
  restoreActiveTab() {
    const activeTabId = localStorage.getItem(this.activeTabStorage);
    if (!activeTabId) return;

    const tabElement = this.find(`#${activeTabId}`);
    if (tabElement) {
      const tab = new bootstrap.Tab(tabElement);
      tab.show();
    }
  }

  /**
   * Set up main table events
   */
  setupMainTableEvents(table) {
    // Row moved event
    table.on("rowMoved", (row) => {
      this.updateSequences(table, 'menu');
    });

    // Row selection changed
    table.on("rowSelectionChanged", (data, rows) => {
      const activateBtn = this.find('#activate-row');
      const deactivateBtn = this.find('#deactivate-row');
      
      if (activateBtn && deactivateBtn) {
        const hasSelection = data.length > 0;
        activateBtn.disabled = !hasSelection;
        deactivateBtn.disabled = !hasSelection;
      }
    });
  }

  /**
   * Set up restaurant table events
   */
  setupRestaurantTableEvents(table) {
    // Row moved event
    table.on("rowMoved", (row) => {
      this.updateSequences(table, 'menu');
    });

    // Row selection changed
    table.on("rowSelectionChanged", (data, rows) => {
      const actionsBtn = this.find('#menu-actions');
      if (actionsBtn) {
        actionsBtn.disabled = data.length === 0;
      }
    });
  }

  /**
   * Update sequences after row move
   */
  async updateSequences(table, entityType) {
    const rows = table.getRows();
    
    for (let i = 0; i < rows.length; i++) {
      const rowData = rows[i].getData();
      const newSequence = rows[i].getPosition();
      
      // Update table data
      table.updateData([{ id: rowData.id, sequence: newSequence }]);
      
      // Update server
      try {
        await patch(rowData.url, {
          [entityType]: { sequence: newSequence }
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
    const restaurantId = rowData?.restaurant?.id || this.getRestaurantId();
    
    if (restaurantId) {
      return `<a class='link-dark' href='/restaurants/${restaurantId}/menus/${id}/edit'>${name}</a>`;
    } else {
      // Fallback to old route if restaurant ID not available
      return `<a class='link-dark' href='/menus/${id}/edit'>${name}</a>`;
    }
  }

  /**
   * Update related data when restaurant changes
   */
  updateRelatedData(restaurantId) {
    EventBus.emit(AppEvents.RESTAURANT_SELECT, { 
      restaurant: { id: restaurantId } 
    });

    // Update any dependent tables or forms
    const restaurantMenuTable = this.tableManager.getTable('#restaurant-menu-table');
    if (restaurantMenuTable) {
      const newUrl = `/restaurants/${restaurantId}/menus.json`;
      restaurantMenuTable.setData(newUrl);
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
    // Listen for global menu events
    EventBus.on(AppEvents.MENU_SELECT, (event) => {
      const { menu } = event.detail;
      this.onMenuSelected(menu);
    });

    // Handle bulk actions
    this.bindBulkActions();

    // Handle form submissions
    const menuForms = this.findAll('form[data-menu-form]');
    menuForms.forEach(form => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });
  }

  /**
   * Bind bulk action buttons
   */
  bindBulkActions() {
    // Main table bulk actions
    const activateBtn = this.find('#activate-row');
    const deactivateBtn = this.find('#deactivate-row');
    
    if (activateBtn) {
      this.addEventListener(activateBtn, 'click', () => {
        this.bulkUpdateStatus('menu-table', 'active');
      });
    }
    
    if (deactivateBtn) {
      this.addEventListener(deactivateBtn, 'click', () => {
        this.bulkUpdateStatus('menu-table', 'inactive');
      });
    }

    // Restaurant table bulk actions
    const activateMenuBtn = this.find('#activate-menu');
    const deactivateMenuBtn = this.find('#deactivate-menu');
    
    if (activateMenuBtn) {
      this.addEventListener(activateMenuBtn, 'click', () => {
        this.bulkUpdateStatus('restaurant-menu-table', 'active');
      });
    }
    
    if (deactivateMenuBtn) {
      this.addEventListener(deactivateMenuBtn, 'click', () => {
        this.bulkUpdateStatus('restaurant-menu-table', 'inactive');
      });
    }
  }

  /**
   * Bulk update status for selected rows
   */
  async bulkUpdateStatus(tableId, status) {
    const table = this.tableManager.getTable(`#${tableId}`);
    if (!table) return;

    const selectedRows = table.getSelectedData();
    
    for (const rowData of selectedRows) {
      try {
        // Update table data
        table.updateData([{ id: rowData.id, status: status }]);
        
        // Update server
        await patch(rowData.url, {
          menu: { status: status }
        });
      } catch (error) {
        console.error('Failed to update status:', error);
        this.showNotification(`Failed to update menu status`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(`Updated ${selectedRows.length} menu(s) to ${status}`, 'success');
    }
  }

  /**
   * Handle menu selection
   */
  onMenuSelected(menu) {
    // Update any UI elements that depend on menu selection
    const menuNameElements = this.findAll('.current-menu-name');
    menuNameElements.forEach(el => {
      el.textContent = menu.name;
    });

    // Update breadcrumbs
    const breadcrumbElements = this.findAll('.menu-breadcrumb');
    breadcrumbElements.forEach(el => {
      el.textContent = menu.name;
      const restaurantId = menu.restaurant?.id || this.getRestaurantId();
      if (restaurantId) {
        el.href = `/restaurants/${restaurantId}/menus/${menu.id}`;
      } else {
        el.href = `/menus/${menu.id}`;
      }
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
        this.showNotification('Menu saved successfully', 'success');
        
        // Refresh tables if needed
        this.tableManager.refreshTable('#menu-table');
        this.tableManager.refreshTable('#restaurant-menu-table');
        
        EventBus.emit(AppEvents.DATA_SAVE, { 
          type: 'menu', 
          form: form 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save menu', 'error');
    }
  }

  /**
   * Refresh all menu data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.tableManager.refreshTable('#menu-table');
    this.tableManager.refreshTable('#restaurant-menu-table');
    
    // Refresh forms
    this.formManager.refresh();
    
    // Restore active tab
    this.restoreActiveTab();
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
   * Clean up menu module
   */
  destroy() {
    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, { 
      component: 'MenuModule' 
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new MenuModule(container);
    return module.init();
  }
}
