import { ComponentBase } from '../../components/ComponentBase.js';
import { FormManager } from '../../components/FormManager.js';
import { TableManager } from '../../components/TableManager.js';
import { EventBus, AppEvents } from '../../utils/EventBus.js';
import { ORDER_TABLE_CONFIG } from '../../config/tableConfigs.js';
import { getFormConfig } from '../../config/formConfigs.js';
import { patch, post } from '../../utils/api.js';

/**
 * Order module - handles all order-related functionality
 * Replaces the monolithic ordrs.js file (689 lines → ~300 lines with better structure)
 */
export class OrderModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.formManager = null;
    this.tableManager = null;
    this.restaurantCurrencySymbol = '$';
    
    // Order status constants
    this.ORDER_STATUS = {
      OPENED: 0,
      ORDERED: 20,
      DELIVERED: 25,
      BILL_REQUESTED: 30,
      CLOSED: 40
    };
    
    // Order item status constants
    this.ORDERITEM_STATUS = {
      ADDED: 0,
      REMOVED: 10,
      ORDERED: 20,
      PREPARED: 30,
      DELIVERED: 40
    };
  }

  /**
   * Initialize the order module
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeCurrency();
    this.initializeForms();
    this.initializeTables();
    this.initializeModals();
    this.bindEvents();

    EventBus.emit(AppEvents.COMPONENT_READY, { 
      component: 'OrderModule', 
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
    const formConfig = getFormConfig('order');
    
    this.formManager = new FormManager(this.container);
    this.addChildComponent('formManager', this.formManager);
    this.formManager.init();

    // Set up form-specific event listeners
    this.formManager.on('form:auto-saved', (event) => {
      this.showNotification('Order details saved automatically', 'success');
    });
  }

  /**
   * Initialize table management
   */
  initializeTables() {
    this.tableManager = new TableManager(this.container);
    this.addChildComponent('tableManager', this.tableManager);
    this.tableManager.init();

    // Initialize restaurant order table
    const restaurantOrdrTable = this.find('#restaurant-ordr-table');
    if (restaurantOrdrTable) {
      const restaurantId = restaurantOrdrTable.dataset.restaurantId;
      if (restaurantId) {
        const table = this.tableManager.initializeTable(restaurantOrdrTable, {
          pagination: true,
          paginationSize: 10,
          ajaxURL: `/restaurants/${restaurantId}/ordrs.json`,
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
              title: "Order #", 
              field: "id", 
              formatter: this.orderLinkFormatter, 
              hozAlign: "left"
            },
            {
              title: "Table", 
              field: "tablesetting.name", 
              hozAlign: "left"
            },
            {
              title: "Status", 
              field: "status", 
              formatter: this.statusFormatter, 
              hozAlign: "center"
            },
            {
              title: "Total", 
              field: "total", 
              formatter: "money", 
              hozAlign: "right",
              formatterParams: {
                decimal: ".",
                thousand: ",",
                symbol: this.restaurantCurrencySymbol,
                negativeSign: true,
                precision: 2
              }
            },
            {
              title: "Created", 
              field: "created_at", 
              formatter: "datetime", 
              hozAlign: "right"
            },
            {
              title: "Actions", 
              field: "actions", 
              formatter: this.actionsFormatter, 
              headerSort: false,
              hozAlign: "center"
            }
          ]
        });

        if (table) {
          this.setupTableEvents(table);
        }
      }
    }
  }

  /**
   * Initialize modal functionality
   */
  initializeModals() {
    const modalIds = [
      'openOrderModalLabel',
      'addItemToOrderModalLabel', 
      'filterOrderModalLabel',
      'viewOrderModalLabel'
    ];

    modalIds.forEach(modalId => {
      const modal = this.find(`#${modalId}`);
      if (modal) {
        this.addEventListener(modal, 'shown.bs.modal', () => {
          const backgroundContent = this.find('#backgroundContent');
          if (backgroundContent) {
            backgroundContent.setAttribute('inert', '');
          }
        });

        this.addEventListener(modal, 'hidden.bs.modal', () => {
          const backgroundContent = this.find('#backgroundContent');
          if (backgroundContent) {
            backgroundContent.removeAttribute('inert');
          }
        });
      }
    });
  }

  /**
   * Set up table events
   */
  setupTableEvents(table) {
    // Row selection changed
    table.on("rowSelectionChanged", (data, rows) => {
      const hasSelection = data.length > 0;
      
      // Enable/disable bulk action buttons
      const bulkButtons = this.findAll('.bulk-order-action');
      bulkButtons.forEach(btn => {
        btn.disabled = !hasSelection;
      });
    });

    // Row click for order details
    table.on("rowClick", (e, row) => {
      const orderData = row.getData();
      this.showOrderDetails(orderData);
    });
  }

  /**
   * Order link formatter for tables
   */
  orderLinkFormatter(cell) {
    const id = cell.getValue();
    return `<a class='link-primary' href='/ordrs/${id}'>#${id}</a>`;
  }

  /**
   * Status formatter for tables
   */
  statusFormatter(cell) {
    const status = cell.getValue();
    const statusMap = {
      [this.ORDER_STATUS.OPENED]: { text: 'OPENED', class: 'badge-secondary' },
      [this.ORDER_STATUS.ORDERED]: { text: 'ORDERED', class: 'badge-primary' },
      [this.ORDER_STATUS.DELIVERED]: { text: 'DELIVERED', class: 'badge-success' },
      [this.ORDER_STATUS.BILL_REQUESTED]: { text: 'BILL REQUESTED', class: 'badge-warning' },
      [this.ORDER_STATUS.CLOSED]: { text: 'CLOSED', class: 'badge-dark' }
    };
    
    const statusInfo = statusMap[status] || { text: 'UNKNOWN', class: 'badge-light' };
    return `<span class="badge ${statusInfo.class}">${statusInfo.text}</span>`;
  }

  /**
   * Actions formatter for tables
   */
  actionsFormatter(cell) {
    const rowData = cell.getRow().getData();
    const orderId = rowData.id;
    
    return `
      <div class="btn-group btn-group-sm">
        <button class="btn btn-outline-primary btn-sm view-order" data-order-id="${orderId}">
          <i class="fas fa-eye"></i>
        </button>
        <button class="btn btn-outline-success btn-sm edit-order" data-order-id="${orderId}">
          <i class="fas fa-edit"></i>
        </button>
        <button class="btn btn-outline-danger btn-sm delete-order" data-order-id="${orderId}">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    `;
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
    // Order management buttons
    this.bindOrderActions();
    
    // Payment functionality
    this.bindPaymentActions();
    
    // Modal interactions
    this.bindModalActions();

    // Form submissions
    const orderForms = this.findAll('form[data-order-form]');
    orderForms.forEach(form => {
      this.addEventListener(form, 'submit', (e) => {
        this.handleFormSubmit(e, form);
      });
    });

    // Listen for global events
    EventBus.on(AppEvents.ORDER_CREATE, (event) => {
      this.onOrderCreated(event.detail);
    });

    EventBus.on(AppEvents.ORDER_UPDATE, (event) => {
      this.onOrderUpdated(event.detail);
    });
  }

  /**
   * Bind order action buttons
   */
  bindOrderActions() {
    // Close order button
    const closeOrderBtn = this.find('#close-order');
    if (closeOrderBtn) {
      this.addEventListener(closeOrderBtn, 'click', () => {
        this.closeOrder();
      });
    }

    // Request bill button
    const requestBillBtn = this.find('#request-bill');
    if (requestBillBtn) {
      this.addEventListener(requestBillBtn, 'click', () => {
        this.requestBill();
      });
    }

    // Table action buttons (delegated events)
    this.addEventListener(this.container, 'click', (e) => {
      if (e.target.matches('.view-order')) {
        const orderId = e.target.dataset.orderId;
        this.viewOrder(orderId);
      } else if (e.target.matches('.edit-order')) {
        const orderId = e.target.dataset.orderId;
        this.editOrder(orderId);
      } else if (e.target.matches('.delete-order')) {
        const orderId = e.target.dataset.orderId;
        this.deleteOrder(orderId);
      }
    });
  }

  /**
   * Bind payment-related actions
   */
  bindPaymentActions() {
    // Pay order button
    const payOrderBtn = this.find('#pay-order');
    if (payOrderBtn) {
      this.addEventListener(payOrderBtn, 'click', () => {
        this.processPayment();
      });
    }

    // Refresh payment link button
    const refreshPaymentBtn = this.find('#refreshPaymentLink');
    if (refreshPaymentBtn) {
      this.addEventListener(refreshPaymentBtn, 'click', () => {
        this.refreshPaymentLink();
      });
    }
  }

  /**
   * Bind modal-specific actions
   */
  bindModalActions() {
    // Add item to order modal
    const addItemBtn = this.find('#add-item-to-order');
    if (addItemBtn) {
      this.addEventListener(addItemBtn, 'click', () => {
        this.showAddItemModal();
      });
    }

    // Filter orders modal
    const filterBtn = this.find('#filter-orders');
    if (filterBtn) {
      this.addEventListener(filterBtn, 'click', () => {
        this.showFilterModal();
      });
    }
  }

  /**
   * Close current order
   */
  async closeOrder() {
    const currentOrderId = this.find('#currentOrder')?.textContent;
    if (!currentOrderId) return;

    try {
      await patch(`/ordrs/${currentOrderId}`, {
        ordr: { status: this.ORDER_STATUS.CLOSED }
      });
      
      this.showNotification('Order closed successfully', 'success');
      this.refreshOrderTable();
      
      EventBus.emit(AppEvents.ORDER_UPDATE, { 
        orderId: currentOrderId, 
        status: 'closed' 
      });
    } catch (error) {
      console.error('Failed to close order:', error);
      this.showNotification('Failed to close order', 'error');
    }
  }

  /**
   * Request bill for current order
   */
  async requestBill() {
    const currentOrderId = this.find('#currentOrder')?.textContent;
    const currentTableId = this.find('#currentTable')?.textContent;
    const currentRestaurantId = this.find('#currentRestaurant')?.textContent;
    const currentMenuId = this.find('#currentMenu')?.textContent;

    if (!currentOrderId) return;

    try {
      const orderData = {
        ordr: {
          tablesetting_id: currentTableId,
          restaurant_id: currentRestaurantId,
          menu_id: currentMenuId,
          status: this.ORDER_STATUS.BILL_REQUESTED
        }
      };

      await patch(`/ordrs/${currentOrderId}`, orderData);
      
      this.showNotification('Bill requested successfully', 'success');
      this.refreshOrderTable();
    } catch (error) {
      console.error('Failed to request bill:', error);
      this.showNotification('Failed to request bill', 'error');
    }
  }

  /**
   * Process payment for order
   */
  async processPayment() {
    const tipField = this.find('#tipNumberField');
    const tip = tipField ? parseFloat(tipField.value) || 0 : 0;
    
    const currentOrderId = this.find('#currentOrder')?.textContent;
    if (!currentOrderId) return;

    try {
      const paymentData = {
        ordr: {
          tip: tip,
          status: this.ORDER_STATUS.CLOSED
        }
      };

      await patch(`/ordrs/${currentOrderId}`, paymentData);
      
      this.showNotification('Payment processed successfully', 'success');
      this.refreshOrderTable();
      
      // Reload page if needed
      if (this.locationReload) {
        window.location.reload();
      }
    } catch (error) {
      console.error('Failed to process payment:', error);
      this.showNotification('Failed to process payment', 'error');
    }
  }

  /**
   * Refresh payment link
   */
  async refreshPaymentLink() {
    const amount = this.find('#paymentAmount')?.value;
    const currency = this.find('#paymentCurrency')?.value;
    const restaurantName = this.find('#paymentRestaurantName')?.value;
    const restaurantId = this.find('#paymentRestaurantId')?.value;
    const openOrderId = this.find('#openOrderId')?.value;

    if (!amount || !currency || !restaurantId || !openOrderId) {
      this.showNotification('Missing payment information', 'error');
      return;
    }

    try {
      const response = await post('/create_payment_link', {
        openOrderId,
        amount,
        currency,
        restaurantName,
        restaurantId
      });

      if (response.payment_link) {
        const paymentLinkEl = this.find('#paymentlink');
        const paymentAnchorEl = this.find('#paymentAnchor');
        
        if (paymentLinkEl) paymentLinkEl.textContent = response.payment_link;
        if (paymentAnchorEl) paymentAnchorEl.href = response.payment_link;
        
        // Generate QR code if function exists
        if (typeof fetchQR === 'function') {
          fetchQR(response.payment_link);
        }
        
        this.showNotification('Payment link refreshed', 'success');
      } else {
        throw new Error('No payment link received');
      }
    } catch (error) {
      console.error('Failed to refresh payment link:', error);
      this.showNotification('Failed to generate payment link', 'error');
    }
  }

  /**
   * View order details
   */
  viewOrder(orderId) {
    // Open order details modal or navigate to order page
    window.open(`/ordrs/${orderId}`, '_blank');
  }

  /**
   * Edit order
   */
  editOrder(orderId) {
    window.location.href = `/ordrs/${orderId}/edit`;
  }

  /**
   * Delete order
   */
  async deleteOrder(orderId) {
    if (!confirm('Are you sure you want to delete this order?')) {
      return;
    }

    try {
      await fetch(`/ordrs/${orderId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content
        }
      });
      
      this.showNotification('Order deleted successfully', 'success');
      this.refreshOrderTable();
    } catch (error) {
      console.error('Failed to delete order:', error);
      this.showNotification('Failed to delete order', 'error');
    }
  }

  /**
   * Show order details
   */
  showOrderDetails(orderData) {
    // Implementation for showing order details in modal
    EventBus.emit('modal:show', {
      type: 'order-details',
      data: orderData
    });
  }

  /**
   * Show add item modal
   */
  showAddItemModal() {
    const modal = this.find('#addItemToOrderModalLabel');
    if (modal) {
      const bsModal = new bootstrap.Modal(modal);
      bsModal.show();
    }
  }

  /**
   * Show filter modal
   */
  showFilterModal() {
    const modal = this.find('#filterOrderModalLabel');
    if (modal) {
      const bsModal = new bootstrap.Modal(modal);
      bsModal.show();
    }
  }

  /**
   * Handle order created event
   */
  onOrderCreated(orderData) {
    this.showNotification(`Order #${orderData.id} created`, 'success');
    this.refreshOrderTable();
  }

  /**
   * Handle order updated event
   */
  onOrderUpdated(orderData) {
    this.showNotification(`Order #${orderData.orderId} updated`, 'info');
    this.refreshOrderTable();
  }

  /**
   * Refresh order table
   */
  refreshOrderTable() {
    this.tableManager.refreshTable('#restaurant-ordr-table');
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
        this.showNotification('Order saved successfully', 'success');
        this.refreshOrderTable();
        
        EventBus.emit(AppEvents.DATA_SAVE, { 
          type: 'order', 
          form: form 
        });
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      console.error('Form submission error:', error);
      this.showNotification('Failed to save order', 'error');
    }
  }

  /**
   * Refresh all order data
   */
  refresh() {
    if (this.isDestroyed) return;

    this.refreshOrderTable();
    this.formManager.refresh();
    this.initializeCurrency();
  }

  /**
   * Clean up order module
   */
  destroy() {
    super.destroy();

    EventBus.emit(AppEvents.COMPONENT_DESTROY, { 
      component: 'OrderModule' 
    });
  }

  /**
   * Static factory method
   */
  static init(container = document) {
    const module = new OrderModule(container);
    return module.init();
  }
}
