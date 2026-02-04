// Common order helpers shared by ordrs.js and channels/ordr_channel.js

import $ from 'jquery';

// Fetch the Smartmenu JSON state and dispatch it to the store
function fetchAndDispatchState() {
  try {
    const slug = document.body?.dataset?.smartmenuId;
    if (!slug) return;
    fetch(`/smartmenus/${encodeURIComponent(slug)}.json`, { headers: { Accept: 'application/json' } })
      .then((r) => (r && r.ok ? r.json() : null))
      .then((payload) => {
        if (!payload) return;
        document.dispatchEvent(new CustomEvent('state:update', { detail: payload }));
      })
      .catch(() => {});
  } catch (_) {}
}

export function post(url, body) {
  try { $('#orderCart').hide(); } catch (_) {}
  try { $('#orderCartSpinner').show(); } catch (_) {}

  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content || '';
  const orderSource = (typeof window !== 'undefined' && window.__SM_ORDER_SOURCE) || document.body?.dataset?.orderSource || '';

  try { window.dispatchEvent(new CustomEvent('ordr:request:start', { detail: { method: 'POST', url, body, timestamp: Date.now() } })); } catch (_) {}

  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
      ...(orderSource ? { 'X-Order-Source': String(orderSource) } : {}),
    },
    body: JSON.stringify(body),
  })
    .then((response) => {
      if (!response.ok) throw new Error('Network response was not ok.');
      return response.json().catch(() => ({}));
    })
    .then((data) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:complete', { detail: { method: 'POST', url, status: 200, timestamp: Date.now() } })); } catch (_) {}
      try {
        // If server returned JSON state or a state-like payload, forward it
        const looksLikeState = data && (data.state || data.order || data.menuId || data.tableId || data.restaurant);
        if (looksLikeState) {
          const payload = data.state || data;
          document.dispatchEvent(new CustomEvent('state:update', { detail: payload }));
        }
        // Ensure state is updated for Start Order create and Add Item
        if (/\/(ordrs|ordritems)(\/|$)/.test(url)) { fetchAndDispatchState(); }
      } catch (_) {}
      return data;
    })
    .catch((error) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:error', { detail: { method: 'POST', url, error: String(error), timestamp: Date.now() } })); } catch (_) {}
      throw error;
    });
}

export function patch(url, body) {
  try { $('#orderCart').hide(); } catch (_) {}
  try { $('#orderCartSpinner').show(); } catch (_) {}

  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content || '';
  const orderSource = (typeof window !== 'undefined' && window.__SM_ORDER_SOURCE) || document.body?.dataset?.orderSource || '';

  try { window.dispatchEvent(new CustomEvent('ordr:request:start', { detail: { method: 'PATCH', url, body, timestamp: Date.now() } })); } catch (_) {}

  return fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
      ...(orderSource ? { 'X-Order-Source': String(orderSource) } : {}),
    },
    body: JSON.stringify(body),
  })
    .then(async (response) => {
      if (!response.ok) {
        // Attempt to read error payload for diagnostics
        let errPayload = null;
        try { errPayload = await response.json(); } catch (_) { try { errPayload = await response.text(); } catch (_) {} }
        console.error('[PATCH Error]', { url, status: response.status, body, response: errPayload });
        throw new Error('Network response was not ok.');
      }
      return response.json().catch(() => ({}));
    })
    .then((data) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:complete', { detail: { method: 'PATCH', url, status: 200, timestamp: Date.now() } })); } catch (_) {}
      try {
        // Forward JSON state if present
        const looksLikeState = data && (data.state || data.order || data.menuId || data.tableId || data.restaurant);
        if (looksLikeState) {
          const payload = data.state || data;
          document.dispatchEvent(new CustomEvent('state:update', { detail: payload }));
        }
        // Also refetch state for safety on PATCH to ordrs/ordritems (status or items changes)
        if (/\/(ordrs|ordritems)\//.test(url)) { fetchAndDispatchState(); }
      } catch (_) {}
      return data;
    })
    .catch((error) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:error', { detail: { method: 'PATCH', url, error: String(error), timestamp: Date.now() } })); } catch (_) {}
      throw error;
    });
}

function getContextRoot() {
  // Expect exactly one #contextContainer on SmartMenus pages
  return document.getElementById('contextContainer');
}

export function getCurrentOrderId() {
  const root = getContextRoot();
  // Prefer global state (fresh) over dataset (stale until reload)
  try {
    const gs = window.__SM_STATE || {};
    const id = gs.order && gs.order.id ? String(gs.order.id).trim() : null;
    if (id) return id;
  } catch (_) {}

  // Fallback: legacy DOM nodes
  try {
    const legacy = document.getElementById('currentOrder')?.textContent?.trim();
    if (legacy) return legacy;
  } catch (_) {}

  // Fallback: modal field populated on show.bs.modal
  try {
    const modalOrderId = document.getElementById('a2o_ordr_id')?.textContent?.trim();
    if (modalOrderId) return modalOrderId;
  } catch (_) {}

  if (!root) return null;
  const v = root.dataset?.orderId?.trim();
  if (v) return v;
  return null;
}

export function getCurrentTableId() {
  const root = getContextRoot();
  if (!root) return null;
  const v = root.dataset?.tableId?.trim();
  if (v) return v;
  return null;
}

export function getCurrentMenuId() {
  const root = getContextRoot();
  if (!root) return null;
  const v = root.dataset?.menuId?.trim();
  if (v) return v;
  return null;
}

export function getCurrentEmployeeId() {
  const root = getContextRoot();
  if (!root) return null;
  const v = root.dataset?.employeeId?.trim();
  if (v) return v;
  return null;
}

// Resolve current restaurant id from multiple sources
export function getRestaurantId() {
  const root = getContextRoot();
  // Prefer centralized state first
  try {
    const gs = window.__SM_STATE || {};
    const rid = gs.restaurant && gs.restaurant.id ? String(gs.restaurant.id).trim() : null;
    if (rid) return rid;
  } catch (_) {}

  // Fallback: legacy DOM nodes
  try {
    const legacy = document.getElementById('currentRestaurant')?.textContent?.trim();
    if (legacy) return legacy;
  } catch (_) {}

  // Fallback: any element advertising a restaurant id
  try {
    const anyNode = document.querySelector('[data-restaurant-id]');
    const anyId = anyNode?.dataset?.restaurantId?.trim();
    if (anyId) return anyId;
  } catch (_) {}

  // Fallback: hidden input used by payments
  try {
    const inputVal = document.getElementById('paymentRestaurantId')?.value?.trim();
    if (inputVal) return inputVal;
  } catch (_) {}

  if (!root) return null;
  const fromData = root.dataset?.restaurantId;
  if (fromData) return fromData;
  return null;
}

function getCurrentOrderStatus() {
  // Prefer global state (fresh) over dataset (stale until reload)
  try {
    const gs = window.__SM_STATE || {};
    const st = gs.order && gs.order.status ? String(gs.order.status).toLowerCase() : null;
    if (st) return st;
  } catch (_) {}

  // Fallback: legacy DOM nodes
  try {
    const legacy = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
    if (legacy) return legacy;
  } catch (_) {}

  const root = getContextRoot();
  if (!root) return null;
  return root.dataset?.orderStatus?.trim()?.toLowerCase() || null;
}

// Central initializer for all delegated bindings and UI logic that must survive partial updates
export function initOrderBindings() {
  // Prevent CTA flicker: hide header order row until first state arrives
  (function preventHeaderCtaFlicker() {
    try {
      const header = document.querySelector('.header-order-row');
      if (!header) return;
      // If no state present yet, hide until we receive one
      const hasState = !!(window.__SM_STATE && (window.__SM_STATE.order || window.__SM_STATE.flags));
      if (!hasState) { header.style.visibility = 'hidden'; }

      // Debounced reveal when state includes an order status (stable)
      let t;
      const tryReveal = () => {
        clearTimeout(t);
        t = setTimeout(() => {
          try {
            const s = window.__SM_STATE || {};
            const ok = !!(s.order && typeof s.order.status !== 'undefined');
            if (ok) {
              header.style.visibility = '';
              document.removeEventListener('state:update', tryReveal);
              document.removeEventListener('state:changed', tryReveal);
            }
          } catch (_) {}
        }, 80);
      };
      document.addEventListener('state:update', tryReveal);
      document.addEventListener('state:changed', tryReveal);
    } catch (_) {}
  })();
  // Search filter on menu items
  (function bindSearch() {
    const searchInput = document.getElementById('menu-item-search');
    if (!searchInput) return;
    if (searchInput.__bound) return; // idempotent
    searchInput.__bound = true;
    searchInput.addEventListener('input', function () {
      const term = (searchInput.value || '').trim().toLowerCase();
      const cards = document.querySelectorAll('.menu-item-card');
      if (!term) { cards.forEach((c) => (c.style.display = '')); return; }
      cards.forEach((card) => {
        const name = card.getAttribute('data-name') || '';
        const desc = card.getAttribute('data-description') || '';
        const text = (card.textContent || '').toLowerCase();
        card.style.display = (name.includes(term) || desc.includes(term) || text.includes(term)) ? '' : 'none';
      });
    });
  })();

  // Ensure Start Order modal opens reliably after client-side state clears order
  (function bindOpenOrderModalOpen() {
    if (window.__openOrderModalOpenBound) return;
    window.__openOrderModalOpenBound = true;
    document.addEventListener('click', (evt) => {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('[data-bs-target="#openOrderModal"][data-bs-toggle="modal"]');
      if (!btn) return;
      // Let Bootstrap attempt first; if it errors or target missing, fall back to manual show
      const modalEl = document.getElementById('openOrderModal');
      if (modalEl && window.bootstrap && window.bootstrap.Modal) {
        try {
          // Defer to next tick so Bootstrap's handler runs first; if not shown, show manually
          setTimeout(() => {
            let inst = window.bootstrap.Modal.getInstance(modalEl) || window.bootstrap.Modal.getOrCreateInstance(modalEl);
            // If not visible, show it
            const isShown = modalEl.classList.contains('show');
            if (!isShown) {
              try { inst.show(); } catch (_) { inst = window.bootstrap.Modal.getOrCreateInstance(modalEl); inst.show(); }
            }
          }, 0);
        } catch (_) {
          evt.preventDefault();
          evt.stopPropagation();
          const inst = window.bootstrap.Modal.getOrCreateInstance(modalEl);
          inst.show();
        }
      }
    }, true);
  })();

  // Header CTA visibility is managed by Stimulus state controller

  // Add Item to Order capture (non-tasting only)
  (function bindAddItemCapture() {
    if (window.__addItemCaptureBound) return;
    window.__addItemCaptureBound = true;
    document.addEventListener('click', (evt) => {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('#addItemToOrderButton');
      if (!btn || btn.hasAttribute('disabled')) return;
      const addModalEl = document.getElementById('addItemToOrderModal');
      if (addModalEl?.dataset?.tasting === 'true') return; // let tasting flow handle
      evt.stopPropagation();
      if (evt.stopImmediatePropagation) try { evt.stopImmediatePropagation(); } catch (_) {}
      evt.preventDefault();

      // Require active order
      const currentOrderId = getCurrentOrderId();
      const currentStatus = getCurrentOrderStatus();
      const canAdd = !!currentOrderId && !!currentStatus && currentStatus !== 'billrequested' && currentStatus !== 'closed';
      if (!canAdd) {
        // Close add modal and open Start Order
        if (addModalEl && window.bootstrap && window.bootstrap.Modal) {
          const addInst = window.bootstrap.Modal.getInstance(addModalEl) || window.bootstrap.Modal.getOrCreateInstance(addModalEl);
          addInst.hide();
        }
        const openOrderModal = document.getElementById('openOrderModal');
        if (openOrderModal && window.bootstrap && window.bootstrap.Modal) {
          const openInst = window.bootstrap.Modal.getInstance(openOrderModal) || window.bootstrap.Modal.getOrCreateInstance(openOrderModal);
          openInst.show();
        }
        return;
      }

      const ordrId = document.getElementById('a2o_ordr_id')?.textContent?.trim() || currentOrderId;
      const menuitemId = document.getElementById('a2o_menuitem_id')?.textContent?.trim();
      const price = document.getElementById('a2o_menuitem_price')?.textContent?.trim();
      const restaurantId = getRestaurantId();
      if (!ordrId || !menuitemId || !restaurantId) { console.error('[AddItem][capture] Missing data'); return; }
      const ordritem = { ordritem: { ordr_id: ordrId, menuitem_id: menuitemId, status: 0, ordritemprice: price } };
      post(`/restaurants/${restaurantId}/ordritems`, ordritem)
        .then(() => hideClosestModal(btn))
        .catch((e) => console.error('[AddItem][capture] Post failed:', e));
    }, true);
  })();

  // Utility: hide closest modal for a button element
  function hideClosestModal(btn) {
    try {
      const modalEl = btn.closest && btn.closest('.modal');
      if (modalEl && window.bootstrap && window.bootstrap.Modal) {
        const inst = window.bootstrap.Modal.getInstance(modalEl) || window.bootstrap.Modal.getOrCreateInstance(modalEl);
        inst.hide();
      }
    } catch (_) {}
  }

  // Confirm Order capture
  (function bindConfirmOrderCapture() {
    if (window.__confirmOrderCaptureBound) return;
    window.__confirmOrderCaptureBound = true;
    document.addEventListener('click', (evt) => {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('#confirm-order');
      if (!btn || btn.hasAttribute('disabled')) return;
      evt.stopPropagation();
      if (evt.stopImmediatePropagation) try { evt.stopImmediatePropagation(); } catch (_) {}
      evt.preventDefault();

      if (window.__confirmOrderPosting) return;
      window.__confirmOrderPosting = true;
      const base = { tablesetting_id: getCurrentTableId(), restaurant_id: getRestaurantId(), menu_id: getCurrentMenuId(), status: 20 };
      const eid = getCurrentEmployeeId(); if (eid) { base.employee_id = eid; }
      const restaurantId = getRestaurantId();
      const orderId = getCurrentOrderId();
      if (!restaurantId || !orderId) { console.warn('[ConfirmOrder][capture] Missing id; aborting', { restaurantId, orderId }); window.__confirmOrderPosting = false; return; }
      patch(`/restaurants/${restaurantId}/ordrs/` + orderId, { ordr: base })
        .then(() => hideClosestModal(btn))
        .finally(() => setTimeout(() => { window.__confirmOrderPosting = false; }, 500));
    }, true);
  })();

  // Request Bill confirm capture (modal only)
  (function bindRequestBillCapture() {
    if (window.__requestBillCaptureBound) return;
    window.__requestBillCaptureBound = true;
    document.addEventListener('click', (evt) => {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('#request-bill-confirm');
      if (!btn || btn.hasAttribute('disabled')) return;
      try { console.debug('[RequestBill][capture] click intercepted'); } catch (_) {}
      evt.stopPropagation();
      if (evt.stopImmediatePropagation) try { evt.stopImmediatePropagation(); } catch (_) {}
      evt.preventDefault();

      if (window.__requestBillPosting) return;
      window.__requestBillPosting = true;
      const currentStatus = getCurrentOrderStatus();
      if (currentStatus === 'billrequested' || currentStatus === 'closed') { window.__requestBillPosting = false; return; }
      const restaurantId = getRestaurantId();
      const orderId = getCurrentOrderId();
      if (!restaurantId || !orderId) { console.warn('[RequestBill][capture] Missing id; aborting', { restaurantId, orderId }); window.__requestBillPosting = false; return; }

      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content || '';
      const orderSource = (typeof window !== 'undefined' && window.__SM_ORDER_SOURCE) || document.body?.dataset?.orderSource || '';

      const postJson = (url, body) => {
        return fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            'X-CSRF-Token': csrfToken,
            ...(orderSource ? { 'X-Order-Source': String(orderSource) } : {}),
          },
          body: JSON.stringify(body || {}),
        }).then(async (res) => {
          let data = null;
          try { data = await res.json(); } catch (_) { data = {}; }
          if (!res.ok) {
            const msg = (data && (data.error || data.message)) ? (data.error || data.message) : `Request failed (${res.status})`;
            throw new Error(msg);
          }
          return data;
        });
      };

      postJson(`/restaurants/${restaurantId}/ordrs/${orderId}/request_bill`, {})
        .then((rb) => {
          if (!rb || rb.ok !== true) throw new Error('request_bill failed');
          try { hideClosestModal(btn); } catch (_) {}
        })
        .catch((e) => {
          console.error('[RequestBill][capture] Failed', e);
          try { alert(String(e && e.message ? e.message : e)); } catch (_) {}
        })
        .finally(() => setTimeout(() => { window.__requestBillPosting = false; }, 500));
    }, true);
  })();

  // Pay Order confirm capture (modal only)
  (function bindPayOrderCapture() {
    if (window.__payOrderCaptureBound) return;
    window.__payOrderCaptureBound = true;
    document.addEventListener('click', (evt) => {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('#pay-order-confirm');
      if (!btn || btn.hasAttribute('disabled')) return;
      evt.stopPropagation();
      if (evt.stopImmediatePropagation) try { evt.stopImmediatePropagation(); } catch (_) {}
      evt.preventDefault();

      if (window.__payOrderPosting) return;
      window.__payOrderPosting = true;

      const restaurantId = getRestaurantId();
      const orderId = getCurrentOrderId();
      if (!restaurantId || !orderId) {
        console.warn('[PayOrder][capture] Missing id; aborting', { restaurantId, orderId });
        window.__payOrderPosting = false;
        return;
      }

      const currentStatus = (getCurrentOrderStatus() || '').toLowerCase();

      const successUrl = window.location.href;
      const cancelUrl = window.location.href;

      const ensureBillRequested = () => {
        if (currentStatus === 'billrequested') return Promise.resolve({ ok: true });
        return post(`/restaurants/${restaurantId}/ordrs/${orderId}/request_bill`, {});
      };

      const startPaymentAttempt = () => {
        return post('/payments/payment_attempts', {
          ordr_id: orderId,
          success_url: successUrl,
          cancel_url: cancelUrl,
        });
      };

      ensureBillRequested()
        .then((rb) => {
          if (!rb || rb.ok !== true) throw new Error('request_bill failed');
          return startPaymentAttempt().catch(() => {
            return post(`/restaurants/${restaurantId}/ordrs/${orderId}/payments/checkout_session`, {
              success_url: successUrl,
              cancel_url: cancelUrl,
            });
          });
        })
        .then((cs) => {
          const redirectUrl = (cs && (cs.redirect_url || cs.checkout_url)) ? (cs.redirect_url || cs.checkout_url) : null;
          if (!cs || cs.ok !== true || !redirectUrl) throw new Error('checkout start failed');
          try { hideClosestModal(btn); } catch (_) {}
          window.location.assign(String(redirectUrl));
        })
        .catch((e) => {
          console.error('[PayOrder][capture] Failed to start checkout', e);
        })
        .finally(() => {
          setTimeout(() => { window.__payOrderPosting = false; }, 500);
        });
    }, true);
  })();

  // Enable/disable add-to-order buttons based solely on centralized state flag
  (function bindMenuItemsEnabled() {
    const update = () => {
      try {
        const enabled = !!(window.__SM_STATE && window.__SM_STATE.flags && window.__SM_STATE.flags.menuItemsEnabled === true);
        const $addButtons = $('.addItemToOrder');
        const $tastingButtons = $('.tasting-cta');
        if (enabled) {
          $addButtons.removeAttr('disabled');
          $tastingButtons.removeAttr('disabled');
        } else {
          $addButtons.attr('disabled', 'disabled');
          $tastingButtons.attr('disabled', 'disabled');
        }
      } catch (_) {}
    };

    // Initial run
    update();
    // Re-evaluate on state changes
    if (!window.__menuItemsEnabledBound) {
      window.__menuItemsEnabledBound = true;
      document.addEventListener('state:changed', update);
    }
  })();

  function resolveGrossForTipCalc() {
    const domGross = parseFloat(String($('#orderGross').text() || '').replace(/[^0-9.\-]/g, ''));
    if (Number.isFinite(domGross) && domGross > 0) return domGross;
    try {
      const gsGross = window.__SM_STATE?.totals?.gross;
      const parsed = typeof gsGross === 'number' ? gsGross : parseFloat(String(gsGross || ''));
      if (Number.isFinite(parsed) && parsed > 0) return parsed;
    } catch (_) {}
    return NaN;
  }

  function resolveCurrencySymbolForTipCalc() {
    const dom = String($('#restaurantCurrency').text() || '');
    if (dom) return dom;
    try {
      return String(window.__SM_STATE?.totals?.currency?.symbol || '');
    } catch (_) {
      return '';
    }
  }

  function recalcTipAndTotals() {
    const gross = resolveGrossForTipCalc();
    if (!Number.isFinite(gross) || gross <= 0) return;

    const currency = resolveCurrencySymbolForTipCalc();
    const tipRaw = $('#tipNumberField').val();
    const tip = Number.isFinite(parseFloat(tipRaw)) ? parseFloat(tipRaw) : 0;
    const total = parseFloat((tip + gross).toFixed(2));

    $('#orderGrandTotal').text(currency + total.toFixed(2));
    if ($('#paymentAmount').length) {
      $('#paymentAmount').val(Math.round(total * 100));
    }
  }

  // Tip presets and manual change (delegated so modal content replacement doesn't drop bindings)
  $(document).off('click.tipPreset.core').on('click.tipPreset.core', '.tipPreset', function () {
    const presetTipPercentage = parseFloat($(this).text());
    const gross = resolveGrossForTipCalc();
    if (!Number.isFinite(gross) || gross <= 0) return;
    const tip = ((gross / 100) * presetTipPercentage).toFixed(2);
    $('#tipNumberField').val(tip);
    recalcTipAndTotals();
    $('#paymentlink').text('');
    $('#paymentAnchor').prop('href', '');
    $('#paymentQR').html('');
    $('#paymentQR').text('');
  });
  $(document).off('change.tipNumberField.core').on('change.tipNumberField.core', '#tipNumberField', function () {
    const parsed = parseFloat($(this).val());
    $(this).val((Number.isFinite(parsed) ? parsed : 0).toFixed(2));
    recalcTipAndTotals();
  });

  // When opening the Pay modal without a full refresh, ensure totals are computed at show-time.
  // Bootstrap modal events bubble, so we can delegate from document.
  $(document)
    .off('shown.bs.modal.payOrderTip')
    .on('shown.bs.modal.payOrderTip', '#payOrderModal', function () {
      recalcTipAndTotals();
    });

  // Start Order modal: party size selector (no typing)
  (function bindOrderCapacityUi() {
    function clamp(n, min, max) {
      const nn = Number.isFinite(n) ? n : parseInt(String(n || ''), 10);
      const safe = Number.isFinite(nn) ? nn : min;
      return Math.max(min, Math.min(max, safe));
    }

    function getBounds() {
      const input = document.getElementById('orderCapacity');
      const min = parseInt(input?.dataset?.min || '1', 10) || 1;
      const max = parseInt(input?.dataset?.max || '1', 10) || 1;
      return { input, min, max };
    }

    function setCapacity(nextValue) {
      const { input, min, max } = getBounds();
      if (!input) return;
      const value = clamp(nextValue, min, max);
      input.value = String(value);
      const label = document.getElementById('orderCapacityValue');
      if (label) label.textContent = String(value);
      const dec = document.getElementById('orderCapacityDecrement');
      const inc = document.getElementById('orderCapacityIncrement');
      if (dec) dec.toggleAttribute('disabled', value <= min);
      if (inc) inc.toggleAttribute('disabled', value >= max);
    }

    $(document)
      .off('click.orderCapacityPreset.core')
      .on('click.orderCapacityPreset.core', '.orderCapacityPreset', function (evt) {
        evt.preventDefault();
        const cap = parseInt(String($(this).data('capacity') || ''), 10);
        setCapacity(cap);
      });

    $(document)
      .off('click.orderCapacityInc.core')
      .on('click.orderCapacityInc.core', '#orderCapacityIncrement', function (evt) {
        evt.preventDefault();
        const { input, min, max } = getBounds();
        if (!input) return;
        const current = clamp(input.value, min, max);
        setCapacity(current + 1);
      });

    $(document)
      .off('click.orderCapacityDec.core')
      .on('click.orderCapacityDec.core', '#orderCapacityDecrement', function (evt) {
        evt.preventDefault();
        const { input, min, max } = getBounds();
        if (!input) return;
        const current = clamp(input.value, min, max);
        setCapacity(current - 1);
      });

    // Reset to min each time the modal opens (keeps intent explicit)
    const modalEl = document.getElementById('openOrderModal');
    if (modalEl && !modalEl.__orderCapacityBound) {
      modalEl.__orderCapacityBound = true;
      modalEl.addEventListener('shown.bs.modal', () => {
        const { min } = getBounds();
        setCapacity(min);
      });
    }
  })();

  // Modal inert toggles for accessibility
  (function bindModalInert() {
    const ids = ['openOrderModalLabel','addItemToOrderModalLabel','filterOrderModalLabel','viewOrderModalLabel','requestBillModalLabel','payOrderModalLabel'];
    ids.forEach((id) => {
      const el = document.getElementById(id);
      if (!el || el.__inertBound) return;
      el.__inertBound = true;
      el.addEventListener('shown.bs.modal', () => { document.getElementById('backgroundContent')?.setAttribute('inert', ''); });
      el.addEventListener('hidden.bs.modal', () => { document.getElementById('backgroundContent')?.removeAttribute('inert'); });
    });
  })();

  // Add name to participant
  $(document).off('click.addNameToParticipant.core').on('click.addNameToParticipant.core', '#addNameToParticipantButton', function (event) {
    const modal = document.getElementById('addNameToParticipantModal');
    if (!modal) return;
    const ordrparticipant = { ordrparticipant: { name: modal.querySelector('#name')?.value } };
    patch('/ordrparticipants/' + (document.getElementById('contextContainer')?.dataset?.participantId || ''), ordrparticipant);
    event.preventDefault();
  });

  // Locale setter
  $(document).off('click.setparticipantlocale.core').on('click.setparticipantlocale.core', '.setparticipantlocale', function (event) {
    const locale = $(this).data('locale');
    const participantId = document.getElementById('contextContainer')?.dataset?.participantId;
    if (participantId) {
      const ordrparticipant = { ordrparticipant: { preferredlocale: locale } };
      patch('/ordrparticipants/' + participantId, ordrparticipant);
    }
    const menuParticipantId = document.getElementById('contextContainer')?.dataset?.menuParticipantId;
    if (menuParticipantId) {
      const menuparticipant = { menuparticipant: { preferredlocale: locale } };
      const restaurantId = getRestaurantId();
      if (!restaurantId) { console.warn('[Locale] Missing restaurant id; aborting'); return; }
      const menuId = getCurrentMenuId();
      patch(`/restaurants/${restaurantId}/menus/${menuId}/menuparticipants/${menuParticipantId}`, menuparticipant);
    }
    event.preventDefault();
  });

  // Remove item
  $(document).off('click.removeItemFromOrder.core').on('click.removeItemFromOrder.core', '.removeItemFromOrderButton', function () {
    const ordrItemId = $(this).attr('data-bs-ordritem_id');
    const ordritem = { ordritem: { status: 10, ordritemprice: 0 } }; // ORDRITEM_REMOVED
    const restaurantId = getRestaurantId();
    if (!restaurantId) { console.warn('[RemoveItem] Missing restaurant id; aborting'); return true; }
    patch(`/restaurants/${restaurantId}/ordritems/${ordrItemId}`, ordritem);
    $('#confirm-order').click();
    return true;
  });

  // Add item to order (standard flow)
  // Removed legacy bubbling handler; capture-phase handler above owns this reliably

  // Removed legacy bubbling start-order handler; capture-phase handler below owns it

  // Capture-phase listener to beat Bootstrap's data-bs-dismiss on #start-order
  (function bindStartOrderCapture() {
    if (window.__startOrderCaptureBound) return;
    window.__startOrderCaptureBound = true;
    const handler = function (evt) {
      const target = evt.target instanceof Element ? evt.target : null;
      if (!target) return;
      const btn = target.closest && target.closest('#start-order');
      if (!btn || btn.hasAttribute('disabled')) return;
      // Intercept before Bootstrap hides the modal
      evt.stopPropagation();
      if (evt.stopImmediatePropagation) try { evt.stopImmediatePropagation(); } catch (_) {}
      evt.preventDefault();

      btn.setAttribute('disabled', 'disabled');
      const ordercapacity = document.getElementById('orderCapacity')?.value || 1;
      const restaurantId = getRestaurantId();
      const tablesettingId = getCurrentTableId();
      const menuId = getCurrentMenuId();
      if (!restaurantId || !tablesettingId || !menuId) {
        console.warn('[StartOrder][capture] Missing required ids; aborting', { restaurantId, tablesettingId, menuId });
        alert('Please select a table before starting an order.');
        btn.removeAttribute('disabled');
        return;
      }
      const payload = { ordr: { tablesetting_id: tablesettingId, restaurant_id: restaurantId, menu_id: menuId, ordercapacity: ordercapacity, status: 0 } };
      if (document.getElementById('currentEmployee')) {
        payload.ordr.employee_id = document.getElementById('currentEmployee').textContent;
      }
      post(`/restaurants/${restaurantId}/ordrs`, payload)
        .then(() => {
          // Hide modal after successful post
          const modalEl = document.getElementById('openOrderModal');
          if (modalEl && window.bootstrap && window.bootstrap.Modal) {
            const inst = window.bootstrap.Modal.getInstance(modalEl) || window.bootstrap.Modal.getOrCreateInstance(modalEl);
            inst.hide();
          }
        })
        .finally(() => {
          btn.removeAttribute('disabled');
        });
    };
    document.addEventListener('click', handler, true); // capture
  })();

  // Removed legacy bubbling pay-order handler; capture-phase handler above owns it

  // Removed legacy bubbling confirm-order handler; capture-phase handler above owns it

  // Removed legacy bubbling request-bill handler; capture-phase handler above owns it
}
