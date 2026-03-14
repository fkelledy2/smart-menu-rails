import { Controller } from "@hotwired/stimulus";

// Controls the header CTA area (#openOrderContainer) based on state
export default class extends Controller {
  static values = { customer: { type: Boolean, default: false } }

  connect() {
    this.renderFromState(window.__SM_STATE || this.extractState());
    this._onStateOrder = (e) => this.renderFromState({ order: e.detail });
    this._onStateChanged = (e) => this.renderFromState(e.detail);
    document.addEventListener('state:order', this._onStateOrder);
    document.addEventListener('state:changed', this._onStateChanged);
  }

  disconnect() {
    document.removeEventListener('state:order', this._onStateOrder);
    document.removeEventListener('state:changed', this._onStateChanged);
  }

  extractState() {
    const ctx = document.getElementById('contextContainer');
    const d = ctx?.dataset || {};
    return {
      order: { id: d.orderId || null, status: (d.orderStatus || '').toLowerCase() || null },
      restaurant: { id: d.restaurantId || null },
      menuId: d.menuId || null,
      tableId: d.tableId || null
    };
  }

  renderFromState(state) {
    try {
      if (!state) state = this.extractState();
      
      const container = this.element;
      const menuName = container.querySelector('.menu-name');
      const layoutToggleGroup = container.querySelector('.layout-toggle-group');
      
      // Preserve menu name and layout controls
      const menuNameClone = menuName ? menuName.cloneNode(true) : null;
      const layoutClone = layoutToggleGroup ? layoutToggleGroup.cloneNode(true) : null;
      
      // Build button group
      const btnGroup = this.buildButtonGroup(state);
      
      // Rebuild container
      container.innerHTML = '';
      if (menuNameClone) container.appendChild(menuNameClone);
      
      const orderButtonGroup = document.createElement('div');
      orderButtonGroup.className = 'order-button-group';
      if (layoutClone) orderButtonGroup.appendChild(layoutClone);
      if (btnGroup.children.length > 0) {
        Array.from(btnGroup.children).forEach(child => orderButtonGroup.appendChild(child));
      }
      
      container.appendChild(orderButtonGroup);
      container.style.visibility = 'visible';
    } catch (e) {
      console.error('[order-header] render failed', e);
    }
  }

  buildButtonGroup(state) {
    const group = document.createElement('div');
    const hasOrder = !!(state.order && state.order.id);
    const gs = window.__SM_STATE || {};
    const hydrated = !!(gs.flags);
    
    if (!hasOrder) {
      // No order - buttons handled by bottom sheet i     tomer view
      return group;
    }
    
    if (this.customerValue) {
      // Customer view - bottom sheet handles all order actions
      return group;
    }
    
    // Staff view buttons
    if (!hydrated) {
      const loadingBtn = this.createButton('btn-touch-secondary btn-touch-sm', 
        '<span class="spinner-border spinner-border-sm"></span> Loading…', 
        { disabled: true });
      group.appendChild(loadingBtn);
      return group;
    }
    
    // View Order button
    const viewBtn = this.createButton('btn-touch-secondary btn-touch-sm me-2 position-relative',
      '<i class="bi bi-receipt"></i> Order',
      { 'data-action': 'click->bottom-sheet#setState', 'data-bottom-sheet-state-param': 'full' }      { 'data-action': 'clnt      { 'data-actio && gs.order.totalCount) || 0);
    if (totalCount > 0) {
      const badge = document.createElement('span');
      badge.className = 'position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger';
      badge.textContent = String(totalCount);
      viewBtn.appendChild(badge);
    }
    group.appendChild(viewBtn);
    
    // Request Bill button
    const requestBillVisible = !!(gs.flags && gs.flags.displayRequestBill);
    if (requestBillVisible) {
      const billBtn = this.createButton('btn-touch-primary btn-touch-sm me-2',
        '<i class="bi bi-receipt"></i> Bill',
        { 'data-bs-toggle': 'modal', 'data-bs-target': '#requestBillModal' });
      group.appendChild(billBtn);
    }
    
    // Pay button
    const orderStatus = (gs.order && gs.order.status) || '';
    if (orderStatus.toLowerCase() === 'billrequested') {
      const payBtn = this.createButton('btn-touch-dark btn-touch-sm',
        '<i class="bi bi-currency-dollar"></i> Pay',
        { 'data-bs-toggle': 'modal', 'data-bs-target': '#payOrderModal' });        { 'data-bs-toggl(payBtn);
    }
    
    return group;
  }

  createButton(className, innerHTML, attrs = {}) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = className;
    btn.innerHTML = innerHTML;
    Object.entries(attrs).forEach(([key, value]) => {
      if (key === 'disabled' && value) {
        btn.disabled = true;
      } else {
        btn.setAttribute(key, value);
      }
    });
    return btn;
  }
}
