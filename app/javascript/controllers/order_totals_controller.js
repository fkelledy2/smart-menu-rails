import { Controller } from "@hotwired/stimulus";

// Keeps bill/pay modals in sync with totals from state
export default class extends Controller {
  static targets = [
    "nettAmount", "serviceAmount", "taxAmount", "grossAmount",
    "grandTotal", "currencySymbol", "requestBillBtn", "payOrderBtn"
  ]

  connect() {
    this._onStateChanged = (e) => this.applyState(e.detail);
    document.addEventListener('state:changed', this._onStateChanged);
    // initial render from dataset/state if available
    this.applyState(this.extractState());
    // Update on modal show to ensure fresh values
    this.element.addEventListener('show.bs.modal', async () => {
      const state = this.extractState();
      // If this is the Pay modal, ensure we at least render current totals immediately
      if (this.element?.id === 'payOrderModal') {
        try { if (typeof this.ensurePayModalContent === 'function') this.ensurePayModalContent(state?.totals || window.__SM_STATE?.totals || null); } catch (_) {}
      }
      // If totals are missing or gross is not positive, force-refresh JSON state
      const gross = state?.totals?.gross;
      const totalsMissing = !state?.totals;
      const grossNotPositive = !(typeof gross === 'number' ? gross : parseFloat(gross || 0)) > 0;
      if (totalsMissing || grossNotPositive) {
        try {
          const slug = document.body?.dataset?.smartmenuId;
          if (slug) {
            const url = `/smartmenus/${encodeURIComponent(slug)}.json?ts=${Date.now()}`;
            const res = await fetch(url, { headers: { Accept: 'application/json', 'Cache-Control': 'no-cache' } });
            if (res && res.ok) {
              const payload = await res.json();
              // Dispatch to central store and re-apply
              document.dispatchEvent(new CustomEvent('state:update', { detail: payload }));
              this.applyState({ order: payload.order, totals: payload.totals });
            }
          }
        } catch (_) {}
      } else {
        this.applyState(state);
      }
    });
  }

  disconnect() {
    document.removeEventListener('state:changed', this._onStateChanged);
  }

  extractState() {
    const ctx = document.getElementById('contextContainer');
    const d = ctx?.dataset || {};
    const gs = window.__SM_STATE || {};
    const go = gs.order || {};
    return {
      order: {
        // Prefer global state over dataset for dynamic fields like order id/status
        id: (go.id || d.orderId || null),
        status: ((go.status || d.orderStatus || '') || '').toLowerCase() || null,
        items: Array.isArray(go.items) ? go.items : [],
        addedCount: typeof go.addedCount !== 'undefined' ? go.addedCount : 0,
        orderedCount: typeof go.orderedCount !== 'undefined' ? go.orderedCount : 0,
        openedCount: typeof go.openedCount !== 'undefined' ? go.openedCount : 0
      },
      totals: gs.totals || null
    };
  }

  applyState(state) {
    try {
      if (!state) return;
      // Deep-merge into the global state to avoid losing counts like openedCount
      const prev = window.__SM_STATE || {};
      const mergedOrder = Object.assign({}, prev.order || {}, state.order || {});
      const mergedTotals = typeof state.totals !== 'undefined' ? state.totals : (prev.totals || null);
      window.__SM_STATE = Object.assign({}, prev, state, { order: mergedOrder, totals: mergedTotals });
      const totals = mergedTotals;
      const order = mergedOrder;
      if (this.element?.id === 'viewOrderModal') {
        this.renderOrderItems(order, totals);
      } else if (this.element?.id === 'requestBillModal') {
        this.renderRequestBill(totals);
      } else if (this.element?.id === 'payOrderModal') {
        if (typeof this.ensurePayModalContent === 'function') this.ensurePayModalContent(totals);
      }
      // Enable Submit Order if there are any 'opened' items (use per-status counts)
      try {
        const openedCount = typeof order?.openedCount === 'number' ? order.openedCount : 0;
        const hasSelected = openedCount > 0;
        this.setDisabledIfExists('#confirm-order', !hasSelected);
      } catch (_) {}
      // Request Bill confirm button enablement follows centralized flag
      try {
        const flags = window.__SM_STATE?.flags || {};
        const canRequestBill = flags.displayRequestBill === true;
        this.setDisabledIfExists('#request-bill-confirm', !canRequestBill);
      } catch (_) {}

      if (!totals) return;

      const symbol = totals.currency?.symbol || '';
      const fmt = (n) => (typeof n === 'number' ? n.toFixed(2) : parseFloat(n || 0).toFixed(2));

      // Update visible amounts if targets exist (used by Pay and Request Bill modals)
      this.updateTextIfExists('#orderCoverCharge', fmt(totals.covercharge));
      this.updateTextIfExists('#orderNett', fmt(totals.nett));
      this.updateTextIfExists('#orderService', fmt(totals.service));
      this.updateTextIfExists('#orderTax', fmt(totals.tax));
      this.updateTextIfExists('#orderGross', fmt(totals.gross));
      this.updateTextIfExists('#orderGrandTotal', `${symbol}${fmt(totals.gross)}`);

      // Pay enablement remains based on payable total and order presence
      const hasPayable = totals.gross > 0 && !!order?.id;
      // Header opener
      this.setDisabledIfExists('#pay-order', !hasPayable);
      // Modal confirm
      this.setDisabledIfExists('#pay-order-confirm', !hasPayable);
    } catch (e) {
      console.error('[order-totals] applyState failed', e);
    }
  }

  renderOrderItems(order, totals) {
    try {
      const body = this.element.querySelector('[data-testid="order-modal-body"]');
      if (!body) return;
      if (!order) { body.innerHTML = ''; return; }
      // If totals are not yet available, do not overwrite server-rendered content.
      // This preserves the server totals row with data-testid until JSON state hydrates.
      if (typeof totals === 'undefined' || totals === null) { return; }
      const currency = totals?.currency?.symbol || '';

      const opened = (order.items || []).filter(i => (i.status || '').toLowerCase() === 'opened');
      const submitted = (order.items || []).filter(i => ['ordered','preparing','ready','delivered','billrequested','paid'].includes((i.status||'').toLowerCase()));

      const row = (cols) => `<div class="row">${cols}</div>`;
      const col = (n, html) => `<div class="col-${n}">${html}</div>`;

      const price = (n) => `${currency}${(typeof n === 'number' ? n : parseFloat(n||0)).toFixed(2)}`;

      let html = '';
      // Header row
      html += row(col(8, '') + col(2, '') + col(2, `<span class="float-end"><b>Price</b></span>`));

      if (opened.length > 0) {
        html += row(col(2, '<p>Selected</p>') + col(10, '<hr>'));
        opened.forEach(it => {
          html += `<div id="ordritem_${it.id}" style="margin-top:5px" class="row" data-testid="order-item-${it.id}">
            <div class="col-8">
              <div class="d-flex w-100 overflow-hidden">
                <p class="text-truncate">
                  <button type="button" class="removeItemFromOrderButton btn-touch-danger btn-touch-icon btn-touch-sm" data-bs-ordritem_id="${it.id}" aria-label="Remove item">
                    <i class="bi bi-trash"></i>
                  </button>
                  ${this.escape(it.name || '')}
                </p>
              </div>
            </div>
            <div class="col-2"></div>
            <div class="col-2"><span class="float-end">${price(it.price)}</span></div>
          </div>`;
        });
      }

      if (submitted.length > 0) {
        html += row(col(2, '<p>Submitted</p>') + col(10, '<hr>'));
        submitted.forEach(it => {
          html += `<div id="ordritem_${it.id}" style="margin-top:5px" class="row">
            <div class="col-8">
              <div class="d-flex w-100 overflow-hidden">
                <p class="text-muted text-truncate">
                  <button type="button" class="btn-touch-dark btn-touch-icon btn-touch-sm" disabled>
                    <i class="bi bi-arrow-right-circle-fill"></i>
                  </button>
                  ${this.escape(it.name || '')}
                </p>
              </div>
            </div>
            <div class="col-2"></div>
            <div class="col-2"><span class="text-muted float-end">${price(it.price)}</span></div>
          </div>`;
        });
      }

      // Totals row (nett) — include test id to match server-rendered markup for tests
      if (typeof totals?.gross !== 'undefined') {
        html += row(
          col(8, '') +
          col(2, '<b>Total:</b>') +
          col(2, `<span class="float-end" data-testid="order-total-amount"><b>${price(totals.gross)}</b></span>`)
        );
      }

      body.innerHTML = html;
    } catch (e) {
      console.error('[order-totals] renderOrderItems failed', e);
    }
  }

  renderRequestBill(totals) {
    try {
      const body = this.element.querySelector('.modal-body');
      if (!body || !totals) return;
      const currency = totals?.currency?.symbol || '';
      const price = (n) => `${currency}${(typeof n === 'number' ? n : parseFloat(n || 0)).toFixed(2)}`;
      const row = (cols) => `<div class="row">${cols}</div>`;
      const col = (n, html) => `<div class="col-${n}">${html}</div>`;

      let html = '';
      // Header
      html += row(col(10, '<b>Item</b>') + col(2, `<span class="float-end"><b>Price</b></span>`));
      // Cover charge
      if ((totals.covercharge || 0) > 0) {
        html += row(col(10, 'Cover charge') + col(2, `<span class="float-end">${price(totals.covercharge)}</span>`));
      }
      // Nett
      html += row(col(10, 'Nett') + col(2, `<span class="float-end">${price(totals.nett)}</span>`));
      // Service
      if ((totals.service || 0) > 0) {
        html += row(col(10, 'Service') + col(2, `<span class="float-end">${price(totals.service)}</span>`));
      }
      // Tax
      if ((totals.tax || 0) > 0) {
        html += row(col(10, 'Tax') + col(2, `<span class="float-end">${price(totals.tax)}</span>`));
      }
      // Divider
      html += row(col(10, '') + col(2, '<hr>'));
      // Total (excluding tip)
      html += row(col(10, '<b>Total</b> <i>(excluding tip)</i>') + col(2, `<span class="float-end"><b>${price(totals.gross)}</b></span>`));

      body.innerHTML = html;
    } catch (e) {
      console.error('[order-totals] renderRequestBill failed', e);
    }
  }

  ensurePayModalContent(totals) {
    try {
      if (!totals) return;
      const body = this.element.querySelector('.modal-body');
      if (!body) return;
      // If server-rendered spans are missing (e.g., initial load had no order), inject a minimal layout
      const hasGross = !!this.element.querySelector('#orderGross');
      if (!hasGross) {
        const currency = totals?.currency?.symbol || this.element.dataset.currencySymbol || '';
        const price = (n) => `${currency}${(typeof n === 'number' ? n : parseFloat(n || 0)).toFixed(2)}`;
        const row = (cols) => `<div class="row">${cols}</div>`;
        const col = (n, html) => `<div class="col-${n}">${html}</div>`;
        const grossVal = (typeof totals.gross === 'number' ? totals.gross : parseFloat(totals.gross || 0)).toFixed(2);
        let html = '';
        // Provide a local currency symbol for tip handlers
        html += `<span id="restaurantCurrency" style="display:none">${this.escape(currency)}</span>`;
        html += row(col(9, '<b>Nett</b>') + col(3, `<span class="float-end"><span id="orderNett">${price(totals.nett||0)}</span></span>`));
        if ((totals.service||0) > 0) html += row(col(9, '<b>Service</b>') + col(3, `<span class="float-end"><span id="orderService">${price(totals.service||0)}</span></span>`));
        if ((totals.tax||0) > 0) html += row(col(9, '<b>Tax</b>') + col(3, `<span class="float-end"><span id="orderTax">${price(totals.tax||0)}</span></span>`));
        html += row(col(9, '') + col(3, '<hr>'));
        html += row(col(9, '<b>Total</b> <i>(excluding tip)</i>') + col(3, `<span class="float-end">${currency}<b><span id="orderGross">${grossVal}</span></b></span>`));
        // Tip presets + manual input
        let tipPresets = [];
        try { tipPresets = JSON.parse(this.element.dataset.tipPresets || '[]'); } catch (_) {}
        let tipHtml = '<div class="row"><p></p><div class="col-12"><span class="float-end">';
        tipHtml += '<div style="position:relative;left:15px" class="btn-toolbar btn-toolbar-sm mb-3" role="toolbar">';
        tipHtml += '<div class="btn-group btn-group-sm mr-2" role="group">';
        tipPresets.forEach(pct => {
          tipHtml += `<button type="button" class="btn-touch-secondary btn-touch-sm"><span class="tipPreset">${pct}</span>%</button>`;
        });
        tipHtml += `<input id="tipNumberField" style="width:80px" type="number" min="0.00" class="form-control float-end text-end" value="0.00">`;
        tipHtml += '</div></div></span></div></div>';
        html += tipHtml;
        html += row(col(9, '') + col(3, '<hr>'));
        html += row(col(9, '<b>Total</b> <i>(including tip)</i>') + col(3, `<span class="float-end"><b><span id="orderGrandTotal">${currency}${grossVal}</span></b></span>`));
        body.innerHTML = html;
      }
    } catch (e) {
      console.error('[order-totals] ensurePayModalContent failed', e);
    }
  }

  escape(s) {
    return String(s).replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[c]));
  }

  updateTextIfExists(selector, text) {
    const el = document.querySelector(selector);
    if (el) {
      if (el.tagName === 'INPUT') {
        el.value = text;
      } else {
        el.textContent = text;
      }
    }
  }

  setDisabledIfExists(selector, disabled) {
    // Prefer the element within this modal to avoid matching the header button
    let el = null;
    try { el = this.element ? this.element.querySelector(selector) : null; } catch (_) {}
    if (!el) { el = document.querySelector(selector); }
    if (el) {
      if (disabled) el.setAttribute('disabled', 'disabled');
      else el.removeAttribute('disabled');
    }
  }
}
