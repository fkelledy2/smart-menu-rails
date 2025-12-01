import { Controller } from "@hotwired/stimulus";

// Controls the header CTA area (#openOrderContainer) based on state
// Listens for state:order and state:changed events and renders appropriate buttons
export default class extends Controller {
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
      menuId: d.menuId || null
    };
  }

  renderFromState(state) {
    try {
      if (!state) state = this.extractState();
      const hasOrder = !!(state.order && state.order.id);
      const restaurantId = state.restaurant?.id || this.extractState().restaurant?.id;
      const menuId = state.menuId || this.extractState().menuId;

      // Prefer global JSON state flags
      const gs = window.__SM_STATE || {};
      const requestBillVisible = !!(gs.flags && (gs.flags.displayRequestBill === true));
      const orderStatus = (gs.order && gs.order.status ? String(gs.order.status).toLowerCase() : null);
      const hydrated = !!(gs.flags);

      const btnGroup = document.createElement('div');
      btnGroup.className = 'order-button-group';

      if (!hasOrder) {
        // Start Order button
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn-touch-primary btn-touch-sm';
        btn.setAttribute('data-bs-toggle', 'modal');
        btn.setAttribute('data-bs-restaurant', restaurantId || '');
        btn.setAttribute('data-bs-menu', menuId || '');
        btn.setAttribute('data-bs-target', '#openOrderModal');
        btn.innerHTML = '<i class="bi bi-plus-circle"></i> Start Order';
        btnGroup.appendChild(btn);
      } else {
        // Minimal customer CTA set: View, Request Bill, Pay
        if (!hydrated) {
          const loadingBtn = document.createElement('button');
          loadingBtn.type = 'button';
          loadingBtn.className = 'btn-touch-secondary btn-touch-sm me-2';
          loadingBtn.setAttribute('disabled', 'disabled');
          loadingBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Loading…';
          btnGroup.appendChild(loadingBtn);
        } else {
          const viewBtn = document.createElement('button');
          viewBtn.type = 'button';
          viewBtn.className = 'btn-touch-secondary btn-touch-sm me-2 position-relative';
          viewBtn.setAttribute('data-bs-toggle', 'modal');
          viewBtn.setAttribute('data-bs-target', '#viewOrderModal');
          // Icon + label
          viewBtn.innerHTML = '<i class="bi bi-receipt"></i> Order';
          // Badge with totalCount
          const totalCount = Number((window.__SM_STATE && window.__SM_STATE.order && window.__SM_STATE.order.totalCount) || 0);
          const badge = document.createElement('span');
          badge.className = 'position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger';
          badge.style.transform = 'translate(-40%, -40%)';
          badge.style.fontSize = '0.9rem';
          badge.style.padding = '0.35em 0.6em';
          badge.textContent = String(totalCount);
          if (!(totalCount > 0)) { badge.style.display = 'none'; }
          viewBtn.appendChild(badge);

          btnGroup.appendChild(viewBtn);
        }
        if (hydrated && requestBillVisible) {
          const billBtn = document.createElement('button');
          billBtn.type = 'button';
          billBtn.id = 'request-bill';
          billBtn.className = 'btn-touch-primary btn-touch-sm me-2';
          billBtn.setAttribute('data-bs-toggle', 'modal');
          billBtn.setAttribute('data-bs-target', '#requestBillModal');
          billBtn.textContent = 'Request Bill';
          btnGroup.appendChild(billBtn);
        }
        if (hydrated && orderStatus === 'billrequested') {
          const payBtn = document.createElement('button');
          payBtn.type = 'button';
          payBtn.id = 'pay-order';
          payBtn.className = 'btn-touch-dark btn-touch-sm';
          payBtn.setAttribute('data-bs-toggle', 'modal');
          payBtn.setAttribute('data-bs-target', '#payOrderModal');
          payBtn.textContent = 'Pay';
          btnGroup.appendChild(payBtn);
        }
      }

      // Replace contents, but preserve a leading menu-name span if present
      const container = this.element;
      const nameSpan = container.querySelector('.menu-name');
      container.innerHTML = '';
      if (nameSpan) {
        // Recreate a simple name span to avoid moving nodes across controllers
        const ns = document.createElement('span');
        ns.className = 'menu-name';
        ns.textContent = nameSpan.textContent || '';
        container.appendChild(ns);
      }
      container.appendChild(btnGroup);
    } catch (e) {
      console.error('[order-header] render failed', e);
    }
  }
}
