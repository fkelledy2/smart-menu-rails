import consumer from './consumer';
import { post as commonsPost, patch as commonsPatch, getCurrentOrderId as commonsGetCurrentOrderId, getCurrentTableId as commonsGetCurrentTableId, getCurrentMenuId as commonsGetCurrentMenuId, initOrderBindings as commonsInitOrderBindings } from '../ordr_commons';
import $ from 'jquery';
import * as bootstrap from 'bootstrap';

function post(url, body) {
  return commonsPost(url, body);
}
// Resolve current table id
function getCurrentTableId() { return commonsGetCurrentTableId(); }
// Resolve current menu id
function getCurrentMenuId() { return commonsGetCurrentMenuId(); }
 
function patch(url, body) {
  return commonsPatch(url, body);
}

function fetchQR(paymentLink) {
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(paymentLink)}`;
  const qrCodeImg = document.createElement('img');
  qrCodeImg.src = qrCodeUrl;
  qrCodeImg.alt = 'QR Code';

  const qrContainer = document.getElementById('paymentQR');
  if (qrContainer) {
    qrContainer.innerHTML = '';
    qrContainer.appendChild(qrCodeImg);
  }
}

// Check if we're in a browser environment
const isBrowser = typeof window !== 'undefined' && typeof document !== 'undefined';

// Replace toast with a brief green flash on table selector button
const flashTableSelector = (durationMs = 2000) => {
  if (!isBrowser) return;
  try {
    const el = document.getElementById('table-selector-staff') || document.getElementById('table-selector-customer');
    if (!el) return;
    const prev = el.getAttribute('style') || '';
    // Apply temporary green background + white text
    el.style.transition = el.style.transition || 'background-color 0.25s ease, color 0.25s ease, box-shadow 0.25s ease';
    el.style.backgroundColor = '#4CAF50';
    el.style.color = '#ffffff';
    el.style.boxShadow = '0 0 0 0.15rem rgba(76,175,80,.35)';
    setTimeout(() => {
      el.setAttribute('style', prev);
    }, durationMs);
  } catch (_) {}
};

const updateConnectionStatus = (status, _message) => {
  if (!isBrowser) return;
  // Only flash on successful connect/state update; no UI for other statuses
  if (status === 'connected') {
    flashTableSelector(2000);
  }
};

// (HTML partial decompression removed — JSON-only mode)

const ORDR_OPENED = 0;
const ORDR_ORDERED = 20;
const ORDR_BILLREQUESTED = 30;
const ORDR_CLOSED = 40;

const ORDRITEM_ADDED = 0;
const ORDRITEM_REMOVED = 10;

// Safely resolve current restaurant id from multiple sources and cache it
let __restaurantIdCache = null;
function resolveRestaurantIdOnce() {
  // 1) Hidden div used in many pages
  const el = document.getElementById('currentRestaurant');
  const txt = el && (el.textContent || '').trim();
  if (txt) return txt;
  // 2) Context container data attribute
  const ctx = document.querySelector('#contextContainer');
  const ctxId = ctx && ctx.dataset && ctx.dataset.restaurantId;
  if (ctxId) return ctxId;
  // 3) Hidden input in Pay modal
  const input = document.getElementById('paymentRestaurantId');
  const inputVal = input && (input.value || '').trim();
  if (inputVal) return inputVal;
  // 4) Any element in the DOM with data-restaurant-id
  const anyNode = document.querySelector('[data-restaurant-id]');
  const anyId = anyNode && anyNode.dataset && anyNode.dataset.restaurantId;
  if (anyId) return anyId;
  return null;
}
function getRestaurantId() {
  if (__restaurantIdCache) return __restaurantIdCache;
  const found = resolveRestaurantIdOnce();
  if (found) {
    __restaurantIdCache = found;
  }
  return found;
}
// Resolve current order id from multiple sources
function getCurrentOrderId() { return commonsGetCurrentOrderId(); }
// Try to eagerly cache after DOM ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    __restaurantIdCache = resolveRestaurantIdOnce() || __restaurantIdCache;
  } else {
    document.addEventListener('DOMContentLoaded', () => {
      __restaurantIdCache = resolveRestaurantIdOnce() || __restaurantIdCache;
    });
  }
}

function closeAllModals() {
  if (isBrowser && typeof $ !== 'undefined') {
    $('.modal').modal('hide');
    $('.modal-backdrop').remove();
  }
}

function refreshOrderJSLogic() {
  const searchInput = document.getElementById('menu-item-search');
  if (!searchInput) return;

  searchInput.addEventListener('input', function () {
    const term = searchInput.value.trim().toLowerCase();
    if (term.length === 0) {
      // If search is empty, show all items
      document.querySelectorAll('.menu-item-card').forEach((card) => (card.style.display = ''));
      return;
    }

    document.querySelectorAll('.menu-item-card').forEach(function (card) {
      // Search in data attributes (original English text)
      const name = card.getAttribute('data-name') || '';
      const desc = card.getAttribute('data-description') || '';

      // Search in visible text content (localized text)
      const cardText = card.textContent.toLowerCase();

      if (name.includes(term) || desc.includes(term) || cardText.includes(term)) {
        card.style.display = '';
      } else {
        card.style.display = 'none';
      }
    });
  });

  if ($('#smartmenu').length) {
    const date = new Date();
    const minutes = date.getMinutes();
    const hour = date.getHours();
    const sectionFromOffset = parseInt($('#sectionFromOffset').html());
    const sectionToOffset = parseInt($('#sectionToOffset').html());
    const currentOffset = hour * 60 + minutes;
    // Determine if items can be added: require an active order and allowed status
    const currentOrderId = document.getElementById('currentOrder')?.textContent?.trim();
    const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
    const canAdd = !!currentOrderId && !!statusStr && statusStr !== 'billrequested' && statusStr !== 'closed';
    $('.addItemToOrder').each(function () {
      const fromOffeset = $(this).data('bs-menusection_from_offset');
      const toOffeset = $(this).data('bs-menusection_to_offset');
      const withinWindow = currentOffset >= fromOffeset && currentOffset <= toOffeset;
      if (!withinWindow || !canAdd) { $(this).attr('disabled', 'disabled'); } else { $(this).removeAttr('disabled'); }
    });
  }
  $('#toggleFilters').click(function () {
    $(':checkbox').prop('checked', this.checked);
  });
  $('.tipPreset').click(function () {
    const presetTipPercentage = parseFloat($(this).text());
    const gross = parseFloat($('#orderGross').text());
    const tip = ((gross / 100) * presetTipPercentage).toFixed(2);
    $('#tipNumberField').val(tip);
    const total = parseFloat(parseFloat(tip) + parseFloat(gross)).toFixed(2);
    $('#orderGrandTotal').text($('#restaurantCurrency').text() + parseFloat(total).toFixed(2));
    $('#paymentAmount').val(parseFloat(total).toFixed(2) * 100);
    $('#paymentlink').text('');
    $('#paymentAnchor').prop('href', '');
    $('#paymentQR').html('');
    $('#paymentQR').text('');
  });
  $('#tipNumberField').change(function () {
    $(this).val(parseFloat($(this).val()).toFixed(2));
    const gross = parseFloat($('#orderGross').text());
    const tip = parseFloat($(this).val());
    const total = tip + gross;
    $('#orderGrandTotal').text($('#restaurantCurrency').text() + parseFloat(total).toFixed(2));
  });
  let restaurantCurrencySymbol = '$';
  if ($('#restaurantCurrency').length) {
    restaurantCurrencySymbol = $('#restaurantCurrency').text();
  }
  if ($('#addNameToParticipantModal').length) {
    const addNameToParticipantModal = document.getElementById('addNameToParticipantModal');
    addNameToParticipantModal.addEventListener('show.bs.modal', (event) => {
      const button = event.relatedTarget;
    });
    $('#addNameToParticipantButton').on('click', function (event) {
      const ordrparticipant = {
        ordrparticipant: {
          name: addNameToParticipantModal.querySelector('#name').value,
        },
      };
      patch('/ordrparticipants/' + $('#currentParticipant').text(), ordrparticipant);
      event.preventDefault();
    });
  }
  $(document).on('click', '.setparticipantlocale', function (event) {
    const $target = $(event.target);
    const locale = $target.data('locale') || $target.closest('[data-locale]').data('locale') || $(this).data('locale');
    const ctx = document.getElementById('contextContainer');
    const ctxParticipantId = ctx && ctx.dataset ? (ctx.dataset.participantId || '') : '';
    const ctxMenuParticipantId = ctx && ctx.dataset ? (ctx.dataset.menuParticipantId || '') : '';
    const menuId = getCurrentMenuId() || (ctx && ctx.dataset ? (ctx.dataset.menuId || '') : '');

    const requests = [];

    if (ctxParticipantId) {
      const ordrparticipant = { ordrparticipant: { preferredlocale: locale } };
      requests.push(patch(`/ordrparticipants/${ctxParticipantId}`, ordrparticipant));
    }

    if (ctxMenuParticipantId) {
      const menuparticipant = { menuparticipant: { preferredlocale: locale } };
      const restaurantId = getRestaurantId();
      if (!restaurantId || !menuId) { return; }
      requests.push(patch(`/restaurants/${restaurantId}/menus/${menuId}/menuparticipants/${ctxMenuParticipantId}`, menuparticipant));
    }

    // The Smartmenu UI is server-rendered; locale changes are broadcast as HTML partials in some paths,
    // but the current client only consumes JSON state updates. To ensure the visible menu language
    // updates immediately in customer view, refresh the page after the PATCH completes.
    Promise.allSettled(requests).then(() => {
      try {
        const url = new URL(window.location.href);
        url.searchParams.set('locale', String(locale || '').toLowerCase());
        window.location.replace(url.toString());
      } catch (_) {
        window.location.reload();
      }
    });
    event.preventDefault();
  });
  $('.removeItemFromOrderButton').on('click', function (event) {
    const ordrItemId = $(this).attr('data-bs-ordritem_id');
    const ordritem = {
      ordritem: {
        status: ORDRITEM_REMOVED,
        ordritemprice: 0,
      },
    };
    const restaurantId = getRestaurantId();
    if (!restaurantId) { console.warn('[RemoveItem] Missing restaurant id; aborting'); return true; }
    patch(`/restaurants/${restaurantId}/ordritems/${ordrItemId}`, ordritem);
    $('#confirm-order').click();
    return true;
  });
  const a2oMenuitemImage = document.getElementById('a2o_menuitem_image');
  if (a2oMenuitemImage) {
    a2oMenuitemImage.addEventListener('load', function () {
      document.getElementById('spinner').style.display = 'none';
      document.getElementById('placeholder').style.display = 'none';
      this.style.opacity = 1;
    });
  }
  if ($('#addItemToOrderModal').length) {
    const addItemToOrderModal = document.getElementById('addItemToOrderModal');
    addItemToOrderModal.addEventListener('show.bs.modal', (event) => {
      const button = event.relatedTarget;
      // Utility to toggle tasting-specific controls
      const setTastingControlsVisible = (modalEl, visible, opts = {}) => {
        try {
          const container = modalEl.querySelector('#a2o_tasting_controls');
          const qty = modalEl.querySelector('#a2o_tasting_qty');
          const pairing = modalEl.querySelector('#a2o_tasting_pairing');
          const pairingWrap = modalEl.querySelector('#a2o_tasting_pairing_wrap');
          const elems = [qty, pairing];
          elems.forEach((el) => {
            if (!el) return;
            const group = el.closest('.form-group') || el.closest('.mb-3') || el.parentElement;
            const target = group || el;
            target.style.display = visible ? '' : 'none';
          });
          if (container) {
            container.hidden = !visible;
            container.style.display = visible ? '' : 'none';
          }
          // Control pairing visibility based on allow_pairing opt when visible
          if (pairingWrap) {
            if (!visible) {
              pairingWrap.hidden = true;
              pairingWrap.style.display = 'none';
            } else {
              const allow = !!opts.allowPairing;
              pairingWrap.hidden = !allow;
              pairingWrap.style.display = allow ? '' : 'none';
            }
          }
        } catch (_) {}
      };

      // Always start hidden to avoid stale state
      setTastingControlsVisible(addItemToOrderModal, false);

      if (!button) {
        // Programmatic show (e.g., tasting). Ensure tasting controls are visible when flagged
        const isTasting = addItemToOrderModal?.dataset?.tasting === 'true';
        let base = {};
        try { base = JSON.parse(addItemToOrderModal?.dataset?.tastingBase || '{}'); } catch (_) {}
        const allowPairing = !!base.allow_pairing;
        setTastingControlsVisible(addItemToOrderModal, !!isTasting, { allowPairing });
        return;
      }

      // Opened via regular button => non-tasting. Clear any stale tasting flags and hide controls.
      delete addItemToOrderModal.dataset.tasting;
      delete addItemToOrderModal.dataset.tastingBase;
      // Hide and reset tasting UI for regular items (already hidden above, but reset values)
      setTastingControlsVisible(addItemToOrderModal, false);
      try {
        const qty = addItemToOrderModal.querySelector('#a2o_tasting_qty');
        const pairing = addItemToOrderModal.querySelector('#a2o_tasting_pairing');
        if (qty) qty.value = '1';
        if (pairing) pairing.checked = false;
      } catch (_) {}
      $('#a2o_ordr_id').text(button.getAttribute('data-bs-ordr_id'));
      $('#a2o_menuitem_id').text(button.getAttribute('data-bs-menuitem_id'));
      $('#a2o_menuitem_name').text(button.getAttribute('data-bs-menuitem_name'));
      $('#a2o_menuitem_price').text(
        parseFloat(button.getAttribute('data-bs-menuitem_price')).toFixed(2)
      );
      $('#a2o_menuitem_description').text(button.getAttribute('data-bs-menuitem_description'));
      try {
        const imageElement = addItemToOrderModal.querySelector('#a2o_menuitem_image');
        if (imageElement) {
          imageElement.src = button.getAttribute('data-bs-menuitem_image');
          imageElement.alt = button.getAttribute('data-bs-menuitem_name');
        }
      } catch (err) {
        alert(err);
      }
    });
    // Always reset tasting controls when modal is fully hidden
    addItemToOrderModal.addEventListener('hidden.bs.modal', () => {
      try {
        delete addItemToOrderModal.dataset.tasting;
        delete addItemToOrderModal.dataset.tastingBase;
        const container = addItemToOrderModal.querySelector('#a2o_tasting_controls');
        const pairingWrap = addItemToOrderModal.querySelector('#a2o_tasting_pairing_wrap');
        const qty = addItemToOrderModal.querySelector('#a2o_tasting_qty');
        const pairing = addItemToOrderModal.querySelector('#a2o_tasting_pairing');
        if (container) container.hidden = true;
        if (pairingWrap) pairingWrap.hidden = true;
        if (qty) qty.value = '1';
        if (pairing) pairing.checked = false;
        // Also hide any form group wrappers explicitly
        [qty, pairing].forEach((el) => {
          if (!el) return;
          const group = el.closest('.form-group') || el.closest('.mb-3') || el.parentElement;
          const target = group || el;
          target.style.display = 'none';
        });
      } catch (_) {}
    });
    $('#addItemToOrderButton').on('click', async function (evt) {
      const restaurantId = $('#currentRestaurant').text();
      const addModal = document.getElementById('addItemToOrderModal');
      const isTasting = addModal?.dataset?.tasting === 'true';

      // If tasting, perform the same multi-line posting as ordrs.js (kept in sync)
      if (isTasting) {
        try {
          const ordrId = document.getElementById('currentOrder')?.textContent?.trim();
          const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
          if (!restaurantId || !ordrId || !statusStr || statusStr === 'billrequested' || statusStr === 'closed') {
            console.error('[TASTING][channel] Order not active or status not allowed. Aborting add.');
            return true;
          }
          if (window.__tastingPosting) {
            console.warn('[TASTING][channel] Post already in progress, skipping duplicate');
            return true;
          }
          window.__tastingPosting = true;

          let base = {};
          try {
            base = JSON.parse(addModal.dataset.tastingBase || '{}');
          } catch (e) {
            console.error('[TASTING][channel] Invalid tasting base payload:', e);
            window.__tastingPosting = false;
            return true;
          }

          const qtyField = addModal.querySelector('#a2o_tasting_qty');
          const pairingField = addModal.querySelector('#a2o_tasting_pairing');
          const qty = Math.max(1, parseInt(qtyField?.value || '1'));
          const includePairing = !!pairingField?.checked;

          const tastingPrice = Number(base.tasting_price || 0);
          const pairingPrice = Number(base.pairing_price || 0);
          const allowPairing = !!base.allow_pairing;
          const carrierId = base.carrier_id;
          const pricePer = base.price_per;
          const activeItems = Array.isArray(base.active_items) ? base.active_items : [];

          const lines = [];
          if (tastingPrice > 0 && carrierId) {
            if (pricePer === 'table') {
              lines.push({ menuitem_id: carrierId, price: tastingPrice });
            } else {
              for (let i = 0; i < qty; i++) {
                lines.push({ menuitem_id: carrierId, price: tastingPrice });
              }
            }
          }
          if (includePairing && allowPairing && pairingPrice > 0 && carrierId) {
            for (let i = 0; i < qty; i++) {
              lines.push({ menuitem_id: carrierId, price: pairingPrice });
            }
          }
          activeItems.forEach((it) => {
            const suppCents = Number(it.supplement_cents || 0);
            if (suppCents > 0 && it.id) {
              const unitSupp = suppCents / 100.0;
              for (let i = 0; i < qty; i++) {
                lines.push({ menuitem_id: it.id, price: unitSupp });
              }
            }
          });

          const postOrdritem = (payload) => post(`/restaurants/${restaurantId}/ordritems`, payload);
          const requests = lines.map((l) => ({
            ordritem: {
              ordr_id: ordrId,
              menuitem_id: l.menuitem_id,
              status: ORDRITEM_ADDED,
              ordritemprice: Number(l.price).toFixed(2),
            },
          })).map(postOrdritem);

          Promise.all(requests)
            .then(() => {
              // Clear tasting flags and hide modal
              delete addModal.dataset.tasting;
              delete addModal.dataset.tastingBase;
              if (addModal && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                const addInstance = bootstrap.Modal.getInstance(addModal) || new bootstrap.Modal(addModal);
                addInstance.hide();
              }
            })
            .finally(() => {
              window.__tastingPosting = false;
            })
            .catch((error) => {
              console.error('[TASTING][channel] Error adding items:', error);
            });
          return true;
        } catch (e) {
          console.error('[TASTING][channel] Unexpected error:', e);
          window.__tastingPosting = false;
          return true;
        }
      }

      // Require active order; if missing, prompt Start Order
      let ordrId = document.getElementById('currentOrder')?.textContent?.trim();
      let statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
      const canAdd = !!restaurantId && !!ordrId && !!statusStr && statusStr !== 'billrequested' && statusStr !== 'closed';
      if (!canAdd) {
        if (addModal && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
          const addInstance = bootstrap.Modal.getInstance(addModal) || new bootstrap.Modal(addModal);
          addInstance.hide();
        }
        const openOrderModal = document.getElementById('openOrderModal');
        if (openOrderModal && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
          const openInstance = bootstrap.Modal.getInstance(openOrderModal) || new bootstrap.Modal(openOrderModal);
          openInstance.show();
        }
        evt.preventDefault();
        return false;
      }

      const postOrdritem = (payload) => post(`/restaurants/${restaurantId}/ordritems`, payload);

      let postPromise;
      {
        const resolvedOrderId = $('#a2o_ordr_id').text() || ordrId;
        const ordritem = {
          ordritem: {
            ordr_id: resolvedOrderId,
            menuitem_id: $('#a2o_menuitem_id').text(),
            status: ORDRITEM_ADDED,
            ordritemprice: $('#a2o_menuitem_price').text(),
          },
        };
        console.log('=== ADD ITEM TO ORDER ===');
        console.log('Restaurant ID:', restaurantId);
        console.log('Order ID:', resolvedOrderId);
        console.log('Order item data:', ordritem);
        console.log('POST URL:', `/restaurants/${restaurantId}/ordritems`);
        console.log('========================');
        postPromise = postOrdritem(ordritem);
      }

      // Post and then close modal; do NOT redirect or open View Order (match ordrs.js behavior)
      postPromise
        .then(() => new Promise(resolve => setTimeout(resolve, 1000)))
        .then(() => {
          // Reset tasting flags if any
          if (addModal) {
            delete addModal.dataset.tasting;
            delete addModal.dataset.tastingBase;
          }
          if (addModal && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const addInstance = bootstrap.Modal.getInstance(addModal) || new bootstrap.Modal(addModal);
            addInstance.hide();
          }
          // Small delay to allow modal to fully close
          return new Promise(resolve => setTimeout(resolve, 300));
        })
        .catch((error) => {
          console.error('Error adding item to order:', error);
        });

      return true;
    });
  }
  // Start Order click is handled centrally in ordr_commons.js (capture-phase).
  // Removed legacy bubbling handler here to avoid duplicate POSTs.
  // Delegated handler so replacements of modal content don't drop the binding
  $(document).off('click.confirmOrder').on('click.confirmOrder', '#confirm-order:not([disabled])', function () {
    if (window.__confirmOrderPosting) { return; }
    window.__confirmOrderPosting = true;
    if ($('#currentEmployee').length) {
      const ordr = {
        ordr: {
          tablesetting_id: $('#currentTable').text(),
          employee_id: $('#currentEmployee').text(),
          restaurant_id: getRestaurantId(),
          menu_id: $('#currentMenu').text(),
          status: ORDR_ORDERED,
        },
      };
      const restaurantId = getRestaurantId();
      const orderId = getCurrentOrderId();
      if (!restaurantId || !orderId) { console.warn('[ConfirmOrder] Missing id; aborting', { restaurantId, orderId }); window.__confirmOrderPosting = false; return; }
      patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr)
        .finally(() => setTimeout(() => { window.__confirmOrderPosting = false; }, 500));
    } else {
      const ordr = {
        ordr: {
          tablesetting_id: $('#currentTable').text(),
          restaurant_id: getRestaurantId(),
          menu_id: $('#currentMenu').text(),
          status: ORDR_ORDERED,
        },
      };
      const restaurantId = getRestaurantId();
      const orderId = getCurrentOrderId();
      if (!restaurantId || !orderId) { console.warn('[ConfirmOrder] Missing id; aborting', { restaurantId, orderId }); window.__confirmOrderPosting = false; return; }
      patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr)
        .finally(() => setTimeout(() => { window.__confirmOrderPosting = false; }, 500));
    }
  });
  if ($('#pay-order').length) {
    if (document.getElementById('refreshPaymentLink')) {
      document.getElementById('refreshPaymentLink').addEventListener('click', async () => {
        const amountCents = document.getElementById('paymentAmount').value;
        const restaurantId = document.getElementById('paymentRestaurantId').value;
        const openOrderId = document.getElementById('openOrderId').value;
        let tip = 0;
        if ($('#tipNumberField').length > 0) {
          tip = $('#tipNumberField').val();
        }
        try {
          const response = await fetch(`/restaurants/${restaurantId}/ordrs/${openOrderId}/payments/checkout_session`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
            },
            body: JSON.stringify({ amount_cents: amountCents, tip: tip, success_url: window.location.href, cancel_url: window.location.href }),
          });
          const data = await response.json();
          if (data.checkout_url) {
            $('#paymentlink').text(data.checkout_url);
            $('#paymentAnchor').prop('href', data.checkout_url);
            fetchQR(data.checkout_url);
          } else {
            alert('Failed to generate payment link.');
          }
        } catch (error) {
          console.error('Error:', error);
          alert('Something went wrong.');
        }
      });
    }
  }

}

// Initialize the order channel subscription
function initializeOrderChannel() {
  if (!isBrowser || !document.body) return null;

  let currentOrderId = (function () {
    try { return (typeof commonsGetCurrentOrderId === 'function') ? commonsGetCurrentOrderId() : null; } catch (_) { return null; }
  })();
  const getSlug = () => { try { return document.body?.dataset?.smartmenuId || null; } catch (_) { return null; } };
  let currentIdentifier = currentOrderId || getSlug();
  let usingSlug = !currentOrderId && !!currentIdentifier;
  let subscription = null;

  const subscribeToChannel = () => {
    const orderId = (function () { try { return (typeof commonsGetCurrentOrderId === 'function') ? commonsGetCurrentOrderId() : null; } catch (_) { return null; } })();
    const slug = getSlug();
    const identifier = orderId || slug;
    if (!identifier) return null;
    if (subscription) {
      subscription.unsubscribe();
    }

    currentIdentifier = identifier;
    usingSlug = !orderId && !!slug;

    const params = usingSlug ? { channel: 'OrdrChannel', slug } : { channel: 'OrdrChannel', order_id: orderId };

    subscription = consumer.subscriptions.create(
      params,
      {
        connected() {
          console.log('Connected to OrdrChannel', usingSlug ? `(slug=${slug})` : `(order_id=${orderId})`);
          updateConnectionStatus('connected');
        },

        disconnected() {
          console.log('Disconnected from OrdrChannel');
          updateConnectionStatus('disconnected');
        },

        rejected() {
          console.error('Connection to OrdrChannel was rejected');
          updateConnectionStatus('error');
        },

        received(data) {
          try {
            const payload = data && (data.state || data);
            if (!payload) return;
            // JSON state only
            document.dispatchEvent(new CustomEvent('state:update', { detail: payload }));
            updateConnectionStatus('connected');
          } catch (error) {
            console.error('Error processing received state:', error);
            updateConnectionStatus('error', 'Error processing update');
          }
        },
      }
    );

    return subscription;
  };

  // Initial subscription (slug fallback if no order yet)
  subscribeToChannel();

  // Handle page visibility changes
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && consumer && !consumer.isConnected) {
      console.log('Page became visible, reconnecting...');
      if (consumer.connection && consumer.connection.monitor) {
        consumer.connection.monitor.start();
      }
    }
  });

  // Clean up on page unload
  window.addEventListener('beforeunload', () => {
    if (subscription) {
      subscription.unsubscribe();
    }
  });

  // Re-subscribe when order id appears/changes via state
  document.addEventListener('state:order', (e) => {
    const nextId = e.detail && e.detail.id ? String(e.detail.id) : null;
    if (!nextId) return;
    if (nextId !== currentOrderId) {
      currentOrderId = nextId;
      subscribeToChannel();
    }
  });

  // Global error handler for the channel
  window.handleChannelError = (error) => {
    console.error('Channel error:', error);
    updateConnectionStatus('error', 'Connection error occurred');

    // Try to resubscribe if we're not already reconnecting
    if (consumer && !consumer.reconnectTimer) {
      console.log('Attempting to resubscribe after error...');
      if (subscription) {
        subscription.unsubscribe();
      }
      subscribeToChannel();
    }
  };

  return {
    unsubscribe: () => {
      if (subscription) {
        subscription.unsubscribe();
        subscription = null;
      }
    },
    resubscribe: subscribeToChannel,
  };
}

// Initialize the order channel when the document is ready
if (isBrowser) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => { try { commonsInitOrderBindings(); } catch (_) {} initializeOrderChannel(); });
  } else {
    try { commonsInitOrderBindings(); } catch (_) {}
    initializeOrderChannel();
  }
}
