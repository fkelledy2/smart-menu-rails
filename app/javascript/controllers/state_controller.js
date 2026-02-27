import { Controller } from "@hotwired/stimulus";

// StateController: single source of truth in the browser
// - Reads state from #contextContainer.dataset
// - Dispatches state:* events for view controllers
// - Owns simple UI reconciliations (e.g., header CTA visibility)
export default class extends Controller {
  static values = {
    // optional future bootstrap state via data-state-value (JSON)
    state: Object
  }

  // Apply JSON state payload (replace or shallow-merge critical fields)
  applyJsonState(payload) {
    const prev = this.state || {};
    const hasOrderKey = Object.prototype.hasOwnProperty.call(payload, 'order');
    const next = {
      session: payload.session ?? prev.session ?? null,
      order: hasOrderKey ? {
        id: payload.order?.id ?? null,
        status: payload.order?.status ?? null,
        items: Array.isArray(payload.order?.items) ? payload.order.items : [],
        addedCount: typeof payload.order?.addedCount !== 'undefined' ? payload.order.addedCount : 0,
        orderedCount: typeof payload.order?.orderedCount !== 'undefined' ? payload.order.orderedCount : 0,
        totalCount: typeof payload.order?.totalCount !== 'undefined' ? payload.order.totalCount : 0,
        openedCount: typeof payload.order?.openedCount !== 'undefined' ? payload.order.openedCount : 0,
        removedCount: typeof payload.order?.removedCount !== 'undefined' ? payload.order.removedCount : 0,
        orderedOnlyCount: typeof payload.order?.orderedOnlyCount !== 'undefined' ? payload.order.orderedOnlyCount : 0,
        preparingCount: typeof payload.order?.preparingCount !== 'undefined' ? payload.order.preparingCount : 0,
        readyCount: typeof payload.order?.readyCount !== 'undefined' ? payload.order.readyCount : 0,
        deliveredCount: typeof payload.order?.deliveredCount !== 'undefined' ? payload.order.deliveredCount : 0,
        billrequestedCount: typeof payload.order?.billrequestedCount !== 'undefined' ? payload.order.billrequestedCount : 0,
        paidCount: typeof payload.order?.paidCount !== 'undefined' ? payload.order.paidCount : 0,
        closedCount: typeof payload.order?.closedCount !== 'undefined' ? payload.order.closedCount : 0
      } : {
        // If no 'order' key in payload, preserve previous (old event type)
        id: prev.order?.id ?? null,
        status: prev.order?.status ?? null,
        items: Array.isArray(prev.order?.items) ? prev.order.items : [],
        addedCount: prev.order?.addedCount || 0,
        orderedCount: prev.order?.orderedCount || 0,
        totalCount: prev.order?.totalCount || 0,
        openedCount: prev.order?.openedCount || 0,
        removedCount: prev.order?.removedCount || 0,
        orderedOnlyCount: prev.order?.orderedOnlyCount || 0,
        preparingCount: prev.order?.preparingCount || 0,
        readyCount: prev.order?.readyCount || 0,
        deliveredCount: prev.order?.deliveredCount || 0,
        billrequestedCount: prev.order?.billrequestedCount || 0,
        paidCount: prev.order?.paidCount || 0,
        closedCount: prev.order?.closedCount || 0
      },
      totals: payload.totals ?? prev.totals ?? null,
      flags: payload.flags ?? prev.flags ?? {},
      tableId: payload.tableId ?? prev.tableId ?? null,
      employeeId: payload.employeeId ?? prev.employeeId ?? null,
      menuId: payload.menuId ?? prev.menuId ?? null,
      restaurant: {
        id: payload.restaurant?.id ?? prev.restaurant?.id ?? null,
        allowAlcohol: payload.restaurant?.allowAlcohol ?? prev.restaurant?.allowAlcohol ?? false,
        allowedNow: payload.restaurant?.allowedNow ?? prev.restaurant?.allowedNow ?? false,
        verifyAgeText: payload.restaurant?.verifyAgeText ?? prev.restaurant?.verifyAgeText ?? '',
        salesDisabledText: payload.restaurant?.salesDisabledText ?? prev.restaurant?.salesDisabledText ?? '',
        policyBlockedText: payload.restaurant?.policyBlockedText ?? prev.restaurant?.policyBlockedText ?? ''
      },
      participants: {
        orderParticipantId: payload.participants?.orderParticipantId ?? prev.participants?.orderParticipantId ?? null,
        menuParticipantId: payload.participants?.menuParticipantId ?? prev.participants?.menuParticipantId ?? null
      },
      version: payload.version ?? prev.version
    };
    this.state = next;
  }

  connect() {
    this.applyDatasetState();
    this.dispatchState();

    // Delegated click handler for Pay button (works for server-rendered and JS-rendered)
    this._onPayClick = (e) => {
      const btn = e.target.closest('#cartPayOrder');
      if (!btn) return;
      e.preventDefault();
      const paySection = document.getElementById('cartPaySection');
      if (paySection) {
        // If section is empty, render it now from current state
        if (!paySection.innerHTML.trim()) {
          const st = this.state || {};
          const t = st.totals;
          const s = (t && t.currency && t.currency.symbol) || '';
          paySection.innerHTML = this._renderPaySection(t, s, st.flags || {});
          // Bind Cancel handler on newly created button
          this._bindCancelHandler(paySection);
        }
        paySection.style.display = paySection.style.display === 'none' ? 'block' : 'none';
      }
      // Hide the Pay button itself
      btn.style.display = 'none';
      const sheet = document.getElementById('cartBottomSheet');
      if (sheet) {
        const ctrl = this.application?.getControllerForElementAndIdentifier(sheet, 'bottom-sheet');
        if (ctrl) { ctrl.setState('full'); }
      }
    };
    document.addEventListener('click', this._onPayClick);

    // Global Cancel handler called via onclick on the Cancel button
    window.__cartPayCancel = () => {
      console.debug('[State] Cancel clicked');
      const paySection = document.getElementById('cartPaySection');
      if (paySection) { paySection.style.display = 'none'; }
      // Restore the Pay button and scroll it into view
      const payBtn = document.getElementById('cartPayOrder');
      if (payBtn) {
        payBtn.style.display = 'block';
        setTimeout(() => payBtn.scrollIntoView({ behavior: 'smooth', block: 'center' }), 150);
      }
      const sheet = document.getElementById('cartBottomSheet');
      if (sheet) {
        const ctrl = this.application?.getControllerForElementAndIdentifier(sheet, 'bottom-sheet');
        console.debug('[State] Cancel -> bottom-sheet ctrl:', !!ctrl);
        if (ctrl) { ctrl.setState('half'); }
      }
    };

    // Initial JSON fetch to hydrate items/totals on first load
    try {
      const slug = document.body?.dataset?.smartmenuId;
      const needsHydration = () => {
        const gs = window.__SM_STATE || {};
        // Hydration needed if flags not present or totals missing
        return !gs.flags || typeof gs.flags.displayRequestBill === 'undefined' || !gs.totals;
      };
      const doHydrate = () => {
        if (!slug) return;
        const url = `/smartmenus/${encodeURIComponent(slug)}.json?ts=${Date.now()}`;
        fetch(url, { headers: { Accept: 'application/json', 'Cache-Control': 'no-cache', Pragma: 'no-cache' } })
          .then((r) => (r && r.ok ? r.json() : null))
          .then((payload) => {
            if (payload) {
              try {
                const cnt = Array.isArray(payload?.order?.items) ? payload.order.items.length : 0;
                console.debug('[State][hydrate] items=', cnt, 'orderId=', payload?.order?.id, 'hasTotals=', !!payload?.totals);
              } catch (_) {}
              this.applyJsonState(payload);
              this.dispatchState();
            }
          })
          .catch(() => {});
      };

      // Always hydrate if state is not yet hydrated (even if a previous page set __SM_INIT_FETCHED)
      if (needsHydration()) { doHydrate(); }

      // Rehydrate on BFCache restore
      if (!window.__SM_PAGESHOW_BOUND) {
        window.__SM_PAGESHOW_BOUND = true;
        window.addEventListener('pageshow', (evt) => {
          // evt.persisted is true when restored from bfcache
          if (evt?.persisted || needsHydration()) { doHydrate(); }
        });
      }

      // Rehydrate on visibility change to visible if not hydrated yet
      if (!window.__SM_VISIBILITY_BOUND) {
        window.__SM_VISIBILITY_BOUND = true;
        document.addEventListener('visibilitychange', () => {
          if (document.visibilityState === 'visible' && needsHydration()) {
            doHydrate();
          }
        });
      }
    } catch (_) {}

    // Listen for JSON state updates from the channel
    this._onStateUpdate = (e) => {
      try {
        const incoming = e.detail || {};
        try {
          const cnt = Array.isArray(incoming?.order?.items) ? incoming.order.items.length : 0;
          console.info('[State][update] items=', cnt, 'orderId=', incoming?.order?.id, 'hasTotals=', !!incoming?.totals);
        } catch (_) {}
        this.applyJsonState(incoming);
        this.dispatchState();
      } catch (err) {
        console.error('[StateController] Failed to apply JSON state update', err);
      }
    };
    document.addEventListener('state:update', this._onStateUpdate);

    // Observe attribute changes on the context container (if replaced/updated)
    this.observer = new MutationObserver((mutations) => {
      for (const m of mutations) {
        if (m.type === 'attributes' && m.attributeName?.startsWith('data-')) {
          this.applyDatasetState();
          this.dispatchState();
          break;
        }
      }
    });
    this.observer.observe(this.element, { attributes: true });
  }

  disconnect() {
    if (this.observer) this.observer.disconnect();
    if (this._onStateUpdate) document.removeEventListener('state:update', this._onStateUpdate);
    if (this._onPayClick) document.removeEventListener('click', this._onPayClick);
    delete window.__cartPayCancel;
  }

  // Build state object from dataset
  applyDatasetState() {
    const d = this.element.dataset || {};
    this.state = {
      session: d.session || null,
      order: {
        id: d.orderId || null,
        status: (d.orderStatus || '').toLowerCase() || null
      },
      totals: null,
      tableId: d.tableId || null,
      employeeId: d.employeeId || null,
      menuId: d.menuId || null,
      restaurant: {
        id: d.restaurantId || null,
        allowAlcohol: d.allowAlcohol === '1',
        allowedNow: d.alcoholAllowedNow === '1',
        verifyAgeText: d.alcoholVerifyAgeText || '',
        salesDisabledText: d.alcoholSalesDisabledText || '',
        policyBlockedText: d.alcoholPolicyBlockedText || ''
      },
      participants: {
        orderParticipantId: d.participantId || null,
        menuParticipantId: d.menuParticipantId || null
      }
    };
  }


  // Dispatch broad and targeted events for other controllers
  dispatchState() {
    try { window.__SM_STATE = this.state; } catch (_) {}
    this.dispatch('changed', { detail: this.state });
    this.dispatch('order', { detail: this.state.order });
    this.dispatch('menu', { detail: { menuId: this.state.menuId } });
    this.dispatch('flags', { detail: { restaurant: this.state.restaurant } });

    // Compatibility with existing listeners
    try {
      document.dispatchEvent(new CustomEvent('state:changed', { detail: this.state }));
      document.dispatchEvent(new CustomEvent('state:order', { detail: this.state.order }));
      document.dispatchEvent(new CustomEvent('state:menu', { detail: { menuId: this.state.menuId } }));
      document.dispatchEvent(new CustomEvent('state:flags', { detail: { restaurant: this.state.restaurant } }));

      // bridge to old events if any code still listens
      document.dispatchEvent(new CustomEvent('ordr:updated'));
      document.dispatchEvent(new CustomEvent('ordr:order:updated'));
    } catch (_) {}

    // Sync cart bottom sheet counts and totals with state
    try {
      const totalCount = Number(this.state.order?.totalCount || 0);
      const countEl = document.getElementById('cartItemCount');
      if (countEl) { countEl.textContent = totalCount; }

      const totals = this.state.totals;
      const symbol = (totals && totals.currency && totals.currency.symbol) || '';
      if (totals) {
        const gross = Number(totals.gross || 0);
        const formatted = symbol + gross.toFixed(2);
        const totalAmountEl = document.getElementById('cartTotalAmount');
        if (totalAmountEl) { totalAmountEl.textContent = formatted; }
      }

      // Dynamically re-render cart item rows from state
      this._renderCartItems(this.state, symbol);
    } catch (e) { console.error('[State] cart sync error', e); }
  }

  _renderCartItems(state, symbol) {
    const container = document.getElementById('cartItemsContainer');
    if (!container) return;
    const order = state.order || {};
    // Don't render until items array has been hydrated from JSON (preserve server-rendered ERB)
    if (!Array.isArray(order.items)) return;
    const items = order.items.filter(i => i.status !== 'removed');
    console.debug('[State] _renderCartItems', { itemCount: items.length, orderId: order.id, hasContainer: !!container });

    const opened = items.filter(i => i.status === 'opened');
    const submitted = items.filter(i => ['ordered','preparing','ready','delivered'].includes(i.status));
    const fmt = (n) => symbol + Number(n || 0).toFixed(2);
    const totals = state.totals;
    const flags = state.flags || {};

    let html = '';

    if (opened.length > 0) {
      html += '<div class="cart-sheet__section-label">Selected</div>';
      for (const item of opened) {
        const sizeBit = item.size_name ? ` <span class="text-muted" style="font-size:0.8em;">(${this._esc(item.size_name.replace(/\s*\(.*\)/, ''))})</span>` : '';
        html += `<div class="cart-sheet__item" data-testid="cart-item-${item.id}">
          <button type="button" class="cart-sheet__remove removeItemFromOrderButton" data-bs-ordritem_id="${item.id}" aria-label="Remove item" data-testid="remove-cart-item-${item.id}"><i class="bi bi-x-circle"></i></button>
          <div class="cart-sheet__item-name">${this._esc(item.name)}${sizeBit}</div>
          <div class="cart-sheet__item-price">${fmt(item.price)}</div>
        </div>`;
      }
    }

    if (submitted.length > 0) {
      html += '<div class="cart-sheet__section-label cart-sheet__section-label--muted">Submitted</div>';
      for (const item of submitted) {
        const sizeBit = item.size_name ? ` <span class="text-muted" style="font-size:0.8em;">(${this._esc(item.size_name.replace(/\s*\(.*\)/, ''))})</span>` : '';
        html += `<div class="cart-sheet__item cart-sheet__item--submitted">
          <div class="cart-sheet__status-icon"><i class="bi bi-check-circle-fill text-success"></i></div>
          <div class="cart-sheet__item-name">${this._esc(item.name)}${sizeBit}</div>
          <div class="cart-sheet__item-price text-muted">${fmt(item.price)}</div>
        </div>`;
      }
    }

    if (items.length > 0) {
      const totalFormatted = totals ? fmt(totals.gross) : fmt(0);
      html += `<div class="cart-sheet__totals" data-testid="cart-totals"><div class="cart-sheet__total-row"><span>Total</span><span class="cart-sheet__total-value" id="cartTotalValue">${totalFormatted}</span></div></div>`;
      html += '<div class="cart-sheet__actions" data-testid="cart-actions">';
      if (opened.length > 0) {
        html += '<button type="button" class="btn-touch-primary w-100 submitOrderButton" id="cartSubmitOrder" data-testid="cart-submit-order-btn"><i class="bi bi-send"></i> Submit order</button>';
      }
      const payVisible = flags.payVisible === true;
      const billVisible = flags.displayRequestBill === true && !payVisible;
      html += `<button type="button" class="btn-touch-primary w-100 mt-2" id="cartRequestBill" data-bs-toggle="modal" data-bs-target="#requestBillModal" style="display:${billVisible ? 'block' : 'none'};"><i class="bi bi-receipt"></i> Request Bill</button>`;
      html += `<button type="button" class="btn-touch-dark w-100 mt-2" id="cartPayOrder" style="display:${payVisible ? 'block' : 'none'};"><i class="bi bi-currency-euro"></i> Pay</button>`;
      html += '</div>';

      // Inline pay section (hidden until Pay button clicked)
      html += '<div id="cartPaySection" style="display:none;" class="cart-sheet__pay-section mt-3">';
      if (payVisible && totals) {
        html += this._renderPaySection(totals, symbol, flags);
      }
      html += '</div>';
    } else if (order.id) {
      html += '<div class="text-center text-muted py-4"><i class="bi bi-cart3 fs-1 mb-2 d-block"></i><p>Your cart is empty</p><p class="small">Tap + on any item to add it</p></div>';
    }

    container.innerHTML = html;

    // Bind Cancel button click handler directly after DOM injection
    this._bindCancelHandler(container);

    // If order exists and sheet is closed, open to peek
    const sheet = document.getElementById('cartBottomSheet');
    if (sheet && order.id && items.length > 0) {
      const ctrl = this.application?.getControllerForElementAndIdentifier(sheet, 'bottom-sheet');
      if (ctrl && ctrl.state === 'closed') { ctrl.setState('peek'); }
    }
  }

  _renderPaySection(totals, symbol, flags) {
    if (!totals) return '';
    const fmt = (n) => symbol + Number(n || 0).toFixed(2);
    const sheet = document.getElementById('cartBottomSheet');
    let tipPresets = [];
    try { tipPresets = JSON.parse(sheet?.dataset?.tipPresets || '[]'); } catch (_) {}
    const grossVal = Number(totals.gross || 0).toFixed(2);

    let h = '<hr>';
    h += '<h6 class="fw-bold mb-3">Pay Bill</h6>';
    h += '<div class="bill-line bill-line-header"><span><b>Item</b></span><span class="bill-amount"><b>Price</b></span></div>';
    if ((totals.covercharge || 0) > 0) {
      h += `<div class="bill-line"><span>Cover charge</span><span class="bill-amount" id="orderCoverCharge">${fmt(totals.covercharge)}</span></div>`;
    }
    h += `<div class="bill-line"><span>Nett</span><span class="bill-amount" id="orderNett">${fmt(totals.nett)}</span></div>`;
    if ((totals.service || 0) > 0) {
      h += `<div class="bill-line"><span>Service</span><span class="bill-amount" id="orderService">${fmt(totals.service)}</span></div>`;
    }
    if ((totals.tax || 0) > 0) {
      h += `<div class="bill-line"><span>Tax</span><span class="bill-amount" id="orderTax">${fmt(totals.tax)}</span></div>`;
    }
    h += '<hr>';
    h += `<div class="bill-line bill-line-total"><span><b>Total</b> <i>(excluding tip)</i></span><span class="bill-amount"><b>${symbol}<span id="orderGross">${grossVal}</span></b></span></div>`;
    // Tip presets
    h += '<div class="bill-tip-row"><div class="d-flex flex-wrap align-items-center justify-content-end gap-2 mt-3 mb-3">';
    tipPresets.forEach(pct => {
      h += `<button type="button" class="btn-touch-secondary btn-touch-sm"><span class="tipPreset">${pct}</span>%</button>`;
    });
    h += '<input id="tipNumberField" type="number" min="0.00" class="form-control form-control-sm text-end" style="width:80px" value="0.00">';
    h += '</div></div>';
    h += '<hr>';
    h += `<div class="bill-line bill-line-total"><span><b>Total</b> <i>(including tip)</i></span><span class="bill-amount"><b><span id="orderGrandTotal">${symbol}${grossVal}</span></b></span></div>`;
    // Stripe wallet + hidden inputs
    const orderId = this.state?.order?.id || '';
    const amountCents = Math.round(Number(totals.gross || 0) * 100);
    const currencyCode = sheet?.dataset?.currencyCode || '';
    h += '<div class="d-flex flex-column align-items-center gap-3 mt-4">';
    h += `<div id="wallet-button-container" data-controller="stripe-wallet" data-stripe-wallet-open-order-id-value="${orderId}" data-stripe-wallet-amount-cents-value="${amountCents}" data-stripe-wallet-currency-value="${currencyCode}"></div>`;
    h += `<input type="hidden" id="openOrderId" value="${orderId}">`;
    h += `<input type="hidden" id="paymentAmount" value="${amountCents}">`;
    h += `<input type="hidden" id="paymentCurrency" value="${currencyCode}">`;
    h += '</div>';
    // Cancel + Confirm buttons (50/50)
    const hasPayable = Number(totals.gross || 0) > 0;
    h += '<div class="d-flex gap-2 mt-3">';
    h += '<button id="cartPayCancel" type="button" class="btn-touch-secondary w-50">Cancel</button>';
    h += `<button id="pay-order-confirm" type="button" class="btn-touch-dark w-50" ${hasPayable ? '' : 'disabled'}><i class="bi bi-credit-card"></i> Confirm Payment</button>`;
    h += '</div>';
    return h;
  }

  _bindCancelHandler(parent) {
    const cancelBtn = parent.querySelector('#cartPayCancel');
    if (!cancelBtn) return;
    cancelBtn.addEventListener('click', () => {
      console.debug('[State] Cancel clicked');
      const ps = document.getElementById('cartPaySection');
      if (ps) ps.style.display = 'none';
      const pb = document.getElementById('cartPayOrder');
      if (pb) pb.style.display = 'block';
      const sh = document.getElementById('cartBottomSheet');
      if (sh) {
        const ctrl = this.application?.getControllerForElementAndIdentifier(sh, 'bottom-sheet');
        if (ctrl) { ctrl.setState('half'); }
      }
    });
  }

  _esc(str) {
    const d = document.createElement('div');
    d.textContent = str || '';
    return d.innerHTML;
  }
}
