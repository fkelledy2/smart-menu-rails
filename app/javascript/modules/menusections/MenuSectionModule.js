import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { MENUSECTION_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch } from '../../utils/api.js';

/**
 * MenuSection module - handles all menu section-related functionality
 * Replaces the monolithic menusections.js file (166 lines → ~170 lines with better structure)
 */
export class MenuSectionModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
    this.activeTabStorage = 'activeSectionPillId';
  }

  /**
   * Initialize the menu section module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeForms();
    this.initializeTables();
    this.initializeTabs();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, {
      component: 'MenuSectionModule',
      instance: this,
    });

    return this;
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('menusection');

    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Menu section details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;

      // Special handling for menu select
      if (element.id === 'menusection_menu_id') {
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

    // Initialize menu menusection table
    const menusectionTable = this.find('#menu-menusection-table');
    if (menusectionTable) {
      const menuId = menusectionTable.dataset.menu;
      if (menuId) {
        const restaurantId = this.getRestaurantId();
        const ajaxURL = restaurantId
          ? `/restaurants/${restaurantId}/menus/${menuId}/menusections.json`
          : `/menus/${menuId}/menusections.json`;

        const table = this.tableManager.initializeTable(menusectionTable, {
          ajaxURL: ajaxURL,
          layout: 'fitColumns',
          movableRows: true,
          initialSort: [{ column: 'sequence', dir: 'asc' }],
          columns: [
            {
              formatter: 'rowSelection',
              titleFormatter: 'rowSelection',
              width: 30,
              frozen: true,
              responsive: 0,
              headerHozAlign: 'left',
              hozAlign: 'left',
              headerSort: false,
              cellClick: (e, cell) => cell.getRow().toggleSelect(),
            },
            {
              rowHandle: true,
              formatter: 'handle',
              headerSort: false,
              frozen: true,
              responsive: 0,
              width: 30,
              minWidth: 30,
            },
            {
              title: '',
              field: 'sequence',
              visible: false,
              formatter: 'rownum',
              hozAlign: 'right',
              headerHozAlign: 'right',
              headerSort: false,
            },
            {
              title: 'Name',
              field: 'id',
              responsive: 0,
              formatter: this.linkFormatter,
              hozAlign: 'left',
            },
            {
              title: 'Available',
              field: 'fromhour',
              mutator: this.availabilityMutator,
              hozAlign: 'right',
              headerHozAlign: 'right',
            },
            {
              title: 'Restricted',
              field: 'restricted',
              hozAlign: 'right',
              headerHozAlign: 'right',
            },
            {
              title: 'Status',
              field: 'status',
              formatter: this.statusFormatter,
              responsive: 0,
              minWidth: 100,
              hozAlign: 'right',
              headerHozAlign: 'right',
            },
          ],
          locale: true,
          langs: {
            en: {
              pagination: {
                first: 'First',
                first_title: 'First Page',
                last: 'Last',
                last_title: 'Last Page',
                prev: 'Prev',
                prev_title: 'Previous Page',
                next: 'Next',
                next_title: 'Next Page',
              },
              headerFilters: {
                default: 'filter column...',
              },
              columns: {
                id: 'Name',
                status: 'Status',
                fromhour: 'Available',
                restricted: 'Restricted',
              },
            },
            it: {
              columns: {
                id: 'Nome',
                status: 'Stato',
                fromhour: 'Disponibile',
                restricted: 'Limitato',
              },
            },
          },
        });

        if (table) {
          this.setupTableEvents(table);
        }
      }
    }
  }

  /**
   * Initialize tab functionality with persistence
   */
  initializeTabs() {
    const sectionTabs = this.find('#sectionTabs');
    if (sectionTabs) {
      const pills = sectionTabs.querySelectorAll('button[data-bs-toggle="tab"]');

      pills.forEach((pill) => {
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
   * Set up table events
   */
  setupTableEvents(table) {
    // Row moved event
    table.on('rowMoved', (row) => {
      this.updateSequences(table);
    });

    // Row selection changed
    table.on('rowSelectionChanged', (data, rows) => {
      const actionsBtn = this.find('#menusection-actions');
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
          menusection: { sequence: newSequence },
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
    const status = cell.getRow().getData('data')?.status || cell.getValue();
    return status ? status.toUpperCase() : '';
  }

  /**
   * Link formatter for tables
   */
  linkFormatter(cell) {
    const id = cell.getValue();
    const rowData = cell.getRow().getData('data');
    const name = rowData?.name || id;

    // Get menu ID from table element for nested routes
    const tableElement = cell.getTable().element;
    const menuId = tableElement.dataset.menu || tableElement.dataset.bsMenu;

    const restaurantId = this.getRestaurantId();

    if (restaurantId && menuId) {
      return `<a class='link-dark' href='/restaurants/${restaurantId}/menus/${menuId}/menusections/${id}/edit'>${name}</a>`;
    } else if (menuId) {
      return `<a class='link-dark' href='/menus/${menuId}/menusections/${id}/edit'>${name}</a>`;
    } else {
      // Fallback to old route if menu ID not available
      return `<a class='link-dark' href='/menusections/${id}/edit'>${name}</a>`;
    }
  }

  /**
   * Availability mutator - formats time range display
   */
  availabilityMutator(value, data) {
    const fromHour = String(data.fromhour || 0).padStart(2, '0');
    const fromMin = String(data.frommin || 0).padStart(2, '0');
    const toHour = String(data.tohour || 23).padStart(2, '0');
    const toMin = String(data.tomin || 59).padStart(2, '0');

    return `${fromHour}:${fromMin} - ${toHour}:${toMin}`;
  }

  /**
   * Update related data when menu changes
   */
  updateRelatedData(menuId) {
    EventBus.emit(AppEvents.MENU_SELECT, {
      menu: { id: menuId },
    });

    // Update any dependent tables
    const menusectionTable = this.tableManager.getTable('#menu-menusection-table');
    if (menusectionTable) {
      const restaurantId = this.getRestaurantId();
      const newUrl = restaurantId
        ? `/restaurants/${restaurantId}/menus/${menuId}/menusections.json`
        : `/menus/${menuId}/menusections.json`;
      menusectionTable.setData(newUrl);
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
    const menusectionForms = this.findAll('form[data-menusection-form]');
    menusectionForms.forEach((form) => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Listen for global menu events
    EventBus.on(AppEvents.MENU_SELECT, (event) => {
      const { menu } = event.detail;
      this.onMenuSelected(menu);
    });
  }

  /**
   * Bind bulk action buttons
   */
  bindBulkActions() {
    const activateBtn = this.find('#activate-menusection');
    const deactivateBtn = this.find('#deactivate-menusection');

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
   * Bulk update status for selected rows
   */
  async bulkUpdateStatus(status) {
    const table = this.tableManager.getTable('#menu-menusection-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();

    for (const rowData of selectedRows) {
      try {
        // Update table data
        table.updateData([{ id: rowData.id, status: status }]);

        // Update server
        await patch(rowData.url, {
          menusection: { status: status },
        });
      } catch (error) {
        console.error('Failed to update status:', error);
        this.showNotification(`Failed to update menu section status`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(
        `Updated ${selectedRows.length} menu section(s) to ${status}`,
        'success'
      );
    }
  }

  /**
   * Handle menu selection
   */
  onMenuSelected(menu) {
    // Update any UI elements that depend on menu selection
    const menuNameElements = this.findAll('.current-menu-name');
    menuNameElements.forEach((el) => {
      el.textContent = menu.name;
    });

    // Update breadcrumbs
    const breadcrumbElements = this.findAll('.menu-breadcrumb');
    breadcrumbElements.forEach((el) => {
      el.textContent = menu.name;
      el.href = `/menus/${menu.id}`;
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
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content,
        },
      });

      if (response.ok) {
        this.showNotification('Menu section saved successfully', 'success');

        // Refresh tables if needed
        this.tableManager.refreshTable('#menu-menusection-table');

        EventBus.emit(AppEvents.DATA_SAVE, {
          type: 'menusection',
          form: form,
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save menu section', 'error');
    }
  }

  /**
   * Refresh all menu section data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.tableManager.refreshTable('#menu-menusection-table');

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
   * Clean up menu section module
   */
  destroy() {
    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, {
      component: 'MenuSectionModule',
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new MenuSectionModule(container);
    return module.init();
  }
}
