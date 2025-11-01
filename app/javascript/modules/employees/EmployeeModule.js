import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { EMPLOYEE_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch } from '../../utils/api.js';

/**
 * Employee module - handles all employee-related functionality
 * Replaces the monolithic employees.js file (129 lines → ~150 lines with better structure)
 */
export class EmployeeModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
  }

  /**
   * Initialize the employee module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeForms();
    this.initializeTables();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, {
      component: 'EmployeeModule',
      instance: this,
    });

    return this;
  }

  /**
   * Initialize form management
   */
  initializeForms() {
    const formConfig = getFormConfig('employee');

    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Employee details saved automatically', 'success');
    });

    this.formManager.on('select:initialized', (event) => {
      const { element, tomSelect } = event.detail;

      // Special handling for restaurant select
      if (element.id === 'employee_restaurant_id') {
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

    // Initialize restaurant employee table
    const restaurantEmployeeTable = this.find('#restaurant-employee-table');
    if (restaurantEmployeeTable) {
      const restaurantId = restaurantEmployeeTable.dataset.restaurantId;
      if (restaurantId) {
        const table = this.tableManager.initializeTable(restaurantEmployeeTable, {
          ajaxURL: `/restaurants/${restaurantId}/employees.json`,
          movableRows: true,
          initialSort: [{ column: 'sequence', dir: 'asc' }],
          columns: [
            {
              formatter: 'rowSelection',
              titleFormatter: 'rowSelection',
              width: 30,
              frozen: true,
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
              visible: true,
              formatter: 'rownum',
              responsive: 5,
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
              title: 'Role',
              field: 'role',
              responsive: 5,
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
            it: {
              columns: {
                id: 'Nome',
                role: 'Ruolo',
                status: 'Stato',
              },
            },
            en: {
              columns: {
                id: 'Name',
                role: 'Role',
                status: 'Status',
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
   * Set up table events
   */
  setupTableEvents(table) {
    // Row moved event
    table.on('rowMoved', (row) => {
      this.updateSequences(table);
    });

    // Row selection changed
    table.on('rowSelectionChanged', (data, rows) => {
      const actionsBtn = this.find('#employee-actions');
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
          employee: { sequence: newSequence },
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
    return `<a class='link-dark' href='/employees/${id}/edit'>${name}</a>`;
  }

  /**
   * Update related data when restaurant changes
   */
  updateRelatedData(restaurantId) {
    EventBus.emit(AppEvents.RESTAURANT_SELECT, {
      restaurant: { id: restaurantId },
    });

    // Update any dependent tables
    const employeeTable = this.tableManager.getTable('#restaurant-employee-table');
    if (employeeTable) {
      const newUrl = `/restaurants/${restaurantId}/employees.json`;
      employeeTable.setData(newUrl);
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
    const employeeForms = this.findAll('form[data-employee-form]');
    employeeForms.forEach((form) => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Listen for global restaurant events
    EventBus.on(AppEvents.RESTAURANT_SELECT, (event) => {
      const { restaurant } = event.detail;
      this.onRestaurantSelected(restaurant);
    });
  }

  /**
   * Bind bulk action buttons
   */
  bindBulkActions() {
    const activateBtn = this.find('#activate-employee');
    const deactivateBtn = this.find('#deactivate-employee');

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
    const table = this.tableManager.getTable('#restaurant-employee-table');
    if (!table) return;

    const selectedRows = table.getSelectedData();

    for (const rowData of selectedRows) {
      try {
        // Update table data
        table.updateData([{ id: rowData.id, status: status }]);

        // Update server
        await patch(rowData.url, {
          employee: { status: status },
        });
      } catch (error) {
        console.error('Failed to update status:', error);
        this.showNotification(`Failed to update employee status`, 'error');
      }
    }

    if (selectedRows.length > 0) {
      this.showNotification(`Updated ${selectedRows.length} employee(s) to ${status}`, 'success');
    }
  }

  /**
   * Handle restaurant selection
   */
  onRestaurantSelected(restaurant) {
    // Update any UI elements that depend on restaurant selection
    const restaurantNameElements = this.findAll('.current-restaurant-name');
    restaurantNameElements.forEach((el) => {
      el.textContent = restaurant.name;
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
        this.showNotification('Employee saved successfully', 'success');

        // Refresh tables if needed
        this.tableManager.refreshTable('#restaurant-employee-table');

        EventBus.emit(AppEvents.DATA_SAVE, {
          type: 'employee',
          form: form,
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save employee', 'error');
    }
  }

  /**
   * Refresh all employee data
   */
  refresh() {
    if (this.isDestroyed) return;

    // Refresh tables
    this.tableManager.refreshTable('#restaurant-employee-table');

    // Refresh forms
    this.formManager.refresh();
  }

  /**
   * Clean up employee module
   */
  destroy() {
    // Clean up child components
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, {
      component: 'EmployeeModule',
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new EmployeeModule(container);
    return module.init();
  }
}
