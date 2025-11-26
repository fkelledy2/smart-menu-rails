import consumer from './consumer';
import pako from 'pako';

function post(url, body) {
  $('#orderCart').hide();
  $('#orderCartSpinner').show();
  
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
  if (!csrfToken) {
    console.error('CSRF token not found');
  }
  
  // Dispatch event for testing: request started
  window.dispatchEvent(new CustomEvent('ordr:request:start', { 
    detail: { url, body, timestamp: new Date().getTime() }
  }));
  
  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken || '',
    },
    body: JSON.stringify(body),
  })
    .then(async (response) => {
      $('#orderCartSpinner').hide();
      $('#orderCart').show();
      
      // Dispatch event for testing: request completed
      window.dispatchEvent(new CustomEvent('ordr:request:complete', { 
        detail: { url, status: response.status, timestamp: new Date().getTime() }
      }));

      if (!response.ok) {
        try {
          const data = await response.json();
          console.error('[POST Error]', { url, status: response.status, data, body });
        } catch (_) {
          try {
            const txt = await response.text();
            console.error('[POST Error]', { url, status: response.status, text: txt, body });
          } catch (e2) {
            console.error('[POST Error]', { url, status: response.status, body });
          }
        }
      }
      return response;
    })
    .catch(function (err) {
      console.info(err + ' url: ' + url);
      $('#orderCartSpinner').hide();
      $('#orderCart').show();
      
      // Dispatch event for testing: request failed
      window.dispatchEvent(new CustomEvent('ordr:request:error', { 
        detail: { url, error: err.message, timestamp: new Date().getTime() }
      }));
      
      throw err;
    });
}
function patch(url, body) {
  $('#orderCart').hide();
  $('#orderCartSpinner').show();
  
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
  if (!csrfToken) {
    console.error('CSRF token not found');
  }
  
  fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken || '',
    },
    body: JSON.stringify(body),
  })
    .then((response) => {})
    .catch(function (err) {
      console.info(err + ' url: ' + url);
    });
  return false;
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

// Connection status element to show to users
const createConnectionStatusElement = () => {
  if (!isBrowser) return null;

  // Check if element already exists
  let statusEl = document.getElementById('connection-status');
  if (statusEl) return statusEl;

  // Create new element if it doesn't exist
  statusEl = document.createElement('div');
  statusEl.id = 'connection-status';
  statusEl.style.position = 'fixed';
  statusEl.style.bottom = '5px';
  statusEl.style.right = '5px';
  statusEl.style.padding = '5px 10px';
  statusEl.style.borderRadius = '4px';
  statusEl.style.zIndex = '9999';
  statusEl.style.transition = 'all 0.3s ease';
  statusEl.style.display = 'none';

  // Add to body if it exists
  if (document.body) {
    document.body.appendChild(statusEl);
  } else {
    document.addEventListener('DOMContentLoaded', () => {
      document.body.appendChild(statusEl);
    });
  }

  return statusEl;
};

const connectionStatus = isBrowser ? createConnectionStatusElement() : null;

const updateConnectionStatus = (status, message) => {
  if (!connectionStatus || !isBrowser) return;

  try {
    // Ensure the element is in the DOM
    if (!document.body.contains(connectionStatus) && document.body) {
      document.body.appendChild(connectionStatus);
    }

    connectionStatus.textContent = message;
    connectionStatus.style.display = 'block';

    // Clear previous classes
    connectionStatus.className = '';

    switch (status) {
      case 'connected':
        connectionStatus.style.backgroundColor = '#4CAF50';
        connectionStatus.style.color = 'white';
        // Hide after 3 seconds if connected
        setTimeout(() => {
          if (connectionStatus && connectionStatus.textContent === message) {
            connectionStatus.style.display = 'none';
          }
        }, 3000);
        break;
      case 'disconnected':
        connectionStatus.style.backgroundColor = '#f44336';
        connectionStatus.style.color = 'white';
        break;
      case 'reconnecting':
        connectionStatus.style.backgroundColor = '#FFC107';
        connectionStatus.style.color = 'black';
        break;
      case 'error':
        connectionStatus.style.backgroundColor = '#9C27B0';
        connectionStatus.style.color = 'white';
        break;
      default:
        connectionStatus.style.backgroundColor = '#9E9E9E';
        connectionStatus.style.color = 'white';
    }
  } catch (e) {
    console.error('Error updating connection status:', e);
  }
};

function decompressPartial(compressed) {
  if (!compressed || typeof compressed !== 'string') return '';
  try {
    // Decode the Base64 string to a binary string
    const binaryString = window.atob(compressed);
    const len = binaryString.length;
    // Convert the binary string to a Uint8Array
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    // Decompress using pako (which handles zlib format)
    const decompressed = pako.inflate(bytes, { to: 'string' });
    return decompressed;
  } catch (error) {
    console.error('Error decompressing partial:', error);
    return '';
  }
}

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
function getCurrentOrderId() {
  // 1) Hidden div
  const el = document.getElementById('currentOrder');
  const txt = el && (el.textContent || '').trim();
  if (txt) return txt;
  // 2) Hidden input in Pay modal
  const input = document.getElementById('openOrderId');
  const val = input && (input.value || '').trim();
  if (val) return val;
  return null;
}
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
    const locale = $(this).data('locale');
    if ($('#currentParticipant').text()) {
      const ordrparticipant = {
        ordrparticipant: {
          preferredlocale: locale,
        },
      };
      patch('/ordrparticipants/' + $('#currentParticipant').text(), ordrparticipant);
    }
    if ($('#menuParticipant').text()) {
      const menuparticipant = {
        menuparticipant: {
          preferredlocale: locale,
        },
      };
      const restaurantId = getRestaurantId();
      if (!restaurantId) { console.warn('[Locale] Missing restaurant id; aborting'); return; }
      const menuId = $('#currentMenu').text();
      const menuParticipantId = $('#menuParticipant').text();
      patch(
        `/restaurants/${restaurantId}/menus/${menuId}/menuparticipants/${menuParticipantId}`,
        menuparticipant
      );
    }
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
      if (!button) {
        // Programmatic show (e.g., tasting). Fields already set by ordrs.js
        return;
      }
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
    $('#addItemToOrderButton').on('click', function (evt) {
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

      // Gating: require an active order and allowed status
      const ordrId = document.getElementById('currentOrder')?.textContent?.trim();
      const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
      if (!restaurantId || !ordrId || !statusStr || statusStr === 'billrequested' || statusStr === 'closed') {
        // Close add modal and open Start Order modal if available
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
        const ordritem = {
          ordritem: {
            ordr_id: $('#a2o_ordr_id').text(),
            menuitem_id: $('#a2o_menuitem_id').text(),
            status: ORDRITEM_ADDED,
            ordritemprice: $('#a2o_menuitem_price').text(),
          },
        };
        console.log('=== ADD ITEM TO ORDER ===');
        console.log('Restaurant ID:', restaurantId);
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
  if ($('#start-order').length) {
    $('#start-order').on('click', function () {
      const orderCapacityEl = document.getElementById('orderCapacity');
      const ordercapacity = orderCapacityEl && orderCapacityEl.value ? orderCapacityEl.value : 1;
      if ($('#currentEmployee').length) {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            employee_id: $('#currentEmployee').text(),
            restaurant_id: getRestaurantId(),
            menu_id: $('#currentMenu').text(),
            ordercapacity: ordercapacity,
            status: ORDR_OPENED,
          },
        };
        const restaurantId = getRestaurantId();
        if (!restaurantId) {
          console.warn('[StartOrder] Missing restaurant id; aborting POST');
          return;
        }
        post(`/restaurants/${restaurantId}/ordrs`, ordr);
      } else {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            restaurant_id: getRestaurantId(),
            menu_id: $('#currentMenu').text(),
            ordercapacity: ordercapacity,
            status: ORDR_OPENED,
          },
        };
        const restaurantId = getRestaurantId();
        if (!restaurantId) {
          console.warn('[StartOrder] Missing restaurant id; aborting POST');
          return;
        }
        post(`/restaurants/${restaurantId}/ordrs`, ordr);
      }
    });
  }
  // Delegated handler so replacements of modal content don't drop the binding
  $(document).off('click.confirmOrder').on('click.confirmOrder', '#confirm-order:not([disabled])', function () {
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
      if (!restaurantId || !orderId) { console.warn('[ConfirmOrder] Missing id; aborting', { restaurantId, orderId }); return; }
      patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr);
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
      if (!restaurantId || !orderId) { console.warn('[ConfirmOrder] Missing id; aborting', { restaurantId, orderId }); return; }
      patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr);
    }
  });
  if ($('#request-bill').length) {
    $('#request-bill').on('click', function () {
      if ($('#currentEmployee').length) {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            employee_id: $('#currentEmployee').text(),
            restaurant_id: getRestaurantId(),
            menu_id: $('#currentMenu').text(),
            status: ORDR_BILLREQUESTED,
          },
        };
        const restaurantId = getRestaurantId();
        const orderId = getCurrentOrderId();
        if (!restaurantId || !orderId) { console.warn('[RequestBill] Missing id; aborting', { restaurantId, orderId }); return; }
        patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr);
      } else {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            restaurant_id: getRestaurantId(),
            menu_id: $('#currentMenu').text(),
            status: ORDR_BILLREQUESTED,
          },
        };
        const restaurantId = getRestaurantId();
        const orderId = getCurrentOrderId();
        if (!restaurantId || !orderId) { console.warn('[RequestBill] Missing id; aborting', { restaurantId, orderId }); return; }
        patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr);
      }
    });
  }
  if ($('#pay-order').length) {
    if (document.getElementById('refreshPaymentLink')) {
      document.getElementById('refreshPaymentLink').addEventListener('click', async () => {
        const amount = document.getElementById('paymentAmount').value;
        const currency = document.getElementById('paymentCurrency').value;
        const restaurantName = document.getElementById('paymentRestaurantName').value;
        const restaurantId = document.getElementById('paymentRestaurantId').value;
        const openOrderId = document.getElementById('openOrderId').value;
        try {
          const response = await fetch('/payments/create_payment_link', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
            },
            body: JSON.stringify({ openOrderId, amount, currency, restaurantName, restaurantId }),
          });
          const data = await response.json();
          if (data.payment_link) {
            $('#paymentlink').text(data.payment_link);
            $('#paymentAnchor').prop('href', data.payment_link);
            fetchQR(data.payment_link);
          } else {
            alert('Failed to generate payment link.');
          }
        } catch (error) {
          console.error('Error:', error);
          alert('Something went wrong.');
        }
      });
    }
    $('#pay-order').on('click', function () {
      let tip = 0;
      if ($('#tipNumberField').length > 0) {
        tip = $('#tipNumberField').val();
      }
      if ($('#currentEmployee').length) {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            employee_id: $('#currentEmployee').text(),
            restaurant_id: getRestaurantId(),
            tip: tip,
            menu_id: $('#currentMenu').text(),
            status: ORDR_CLOSED,
          },
        };
        const restaurantId = getRestaurantId();
        const orderId = getCurrentOrderId();
        if (!restaurantId || !orderId) { console.warn('[PayOrder] Missing id; aborting', { restaurantId, orderId }); return; }
        patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr, false);
      } else {
        const ordr = {
          ordr: {
            tablesetting_id: $('#currentTable').text(),
            restaurant_id: getRestaurantId(),
            tip: tip,
            menu_id: $('#currentMenu').text(),
            status: ORDR_CLOSED,
          },
        };
        const restaurantId = getRestaurantId();
        const orderId = getCurrentOrderId();
        if (!restaurantId || !orderId) { console.warn('[PayOrder] Missing id; aborting', { restaurantId, orderId }); return; }
        patch(`/restaurants/${restaurantId}/ordrs/` + orderId, ordr, false);
      }
    });
  }
}

// ============================================================================
// MODAL PRESERVATION FUNCTIONS
// ============================================================================
// These functions preserve modal state during WebSocket updates to prevent
// the modal overlay bug where backdrops remain after DOM updates

/**
 * Captures the current state of all open modals
 * @returns {Array} Array of modal state objects
 */
function preserveModalState() {
  const openModals = [];
  
  // Modals that should NOT be preserved (they should always close after action)
  const doNotPreserveModals = ['addItemToOrderModal'];

  try {
    const modalElements = document.querySelectorAll('.modal.show');

    modalElements.forEach((modalEl) => {
      try {
        // Skip modals that should not be preserved
        if (doNotPreserveModals.includes(modalEl.id)) {
          console.log(`[Modal Preservation] Skipping modal (should close): ${modalEl.id}`);
          const modalInstance = bootstrap.Modal.getInstance(modalEl);
          if (modalInstance) {
            modalInstance.hide();
          }
          return;
        }
        
        const modalInstance = bootstrap.Modal.getInstance(modalEl);
        if (modalInstance) {
          console.log(`[Modal Preservation] Preserving modal: ${modalEl.id}`);

          // Store modal state
          openModals.push({
            id: modalEl.id,
            scrollTop: modalEl.querySelector('.modal-body')?.scrollTop || 0,
            formData: captureFormData(modalEl),
          });

          // Properly hide modal (this removes the backdrop)
          modalInstance.hide();
        }
      } catch (error) {
        console.error(`[Modal Preservation] Error preserving modal ${modalEl.id}:`, error);
      }
    });

    if (openModals.length > 0) {
      console.log(`[Modal Preservation] Preserved ${openModals.length} modal(s)`);
    }
  } catch (error) {
    console.error('[Modal Preservation] Error in preserveModalState:', error);
  }

  return openModals;
}

/**
 * Captures form data from a modal element
 * @param {HTMLElement} modalEl - The modal element
 * @returns {Object} Object containing form field values
 */
function captureFormData(modalEl) {
  const formData = {};

  try {
    const inputs = modalEl.querySelectorAll('input, select, textarea');
    inputs.forEach((input) => {
      if (input.id) {
        if (input.type === 'checkbox') {
          formData[input.id] = input.checked;
        } else if (input.type === 'radio') {
          if (input.checked) {
            formData[input.id] = input.value;
          }
        } else {
          formData[input.id] = input.value;
        }
      }
    });
  } catch (error) {
    console.error('[Modal Preservation] Error capturing form data:', error);
  }

  return formData;
}

/**
 * Restores previously open modals after DOM update
 * @param {Array} openModals - Array of modal state objects
 */
function restoreModalState(openModals) {
  if (!openModals || openModals.length === 0) {
    return;
  }

  try {
    console.log(`[Modal Preservation] Restoring ${openModals.length} modal(s)`);

    openModals.forEach((modalState) => {
      try {
        const modalEl = document.getElementById(modalState.id);
        if (!modalEl) {
          console.warn(`[Modal Preservation] Modal element not found: ${modalState.id}`);
          return;
        }

        // Restore form data
        Object.keys(modalState.formData).forEach((inputId) => {
          const input = document.getElementById(inputId);
          if (input) {
            if (input.type === 'checkbox') {
              input.checked = modalState.formData[inputId];
            } else {
              input.value = modalState.formData[inputId];
            }
          }
        });

        // Restore scroll position
        const modalBody = modalEl.querySelector('.modal-body');
        if (modalBody && modalState.scrollTop > 0) {
          modalBody.scrollTop = modalState.scrollTop;
        }

        // Re-show modal
        const modalInstance = new bootstrap.Modal(modalEl);
        modalInstance.show();

        console.log(`[Modal Preservation] Restored modal: ${modalState.id}`);
      } catch (error) {
        console.error(`[Modal Preservation] Error restoring modal ${modalState.id}:`, error);
      }
    });
  } catch (error) {
    console.error('[Modal Preservation] Error in restoreModalState:', error);
  }
}

/**
 * Fallback function to force close all modals and clean up backdrops
 * Used if modal preservation fails
 */
function closeAllModalsProper() {
  try {
    console.log('[Modal Cleanup] Force closing all modals');

    const modalElements = document.querySelectorAll('.modal.show');

    modalElements.forEach((modalEl) => {
      try {
        const modalInstance = bootstrap.Modal.getInstance(modalEl);
        if (modalInstance) {
          modalInstance.hide();
        }
      } catch (error) {
        console.error('[Modal Cleanup] Error closing modal:', error);
      }
    });

    // Force remove any lingering backdrops
    document.querySelectorAll('.modal-backdrop').forEach((backdrop) => {
      backdrop.remove();
    });

    // Remove modal-open class from body
    document.body.classList.remove('modal-open');
    document.body.style.removeProperty('overflow');
    document.body.style.removeProperty('padding-right');

    console.log('[Modal Cleanup] Cleanup complete');
  } catch (error) {
    console.error('[Modal Cleanup] Error in closeAllModalsProper:', error);
  }
}

// ============================================================================
// END MODAL PRESERVATION FUNCTIONS
// ============================================================================

// Initialize the order channel subscription
function initializeOrderChannel() {
  if (!isBrowser || !document.body) return null;

  const orderId = document.body.dataset.smartmenuId;
  if (!orderId) return null;

  let subscription = null;

  const subscribeToChannel = () => {
    if (subscription) {
      subscription.unsubscribe();
    }

    subscription = consumer.subscriptions.create(
      { channel: 'OrdrChannel', order_id: orderId },
      {
        connected() {
          console.log('Connected to OrdrChannel');
          updateConnectionStatus('connected', 'Connected');
        },

        disconnected() {
          console.log('Disconnected from OrdrChannel');
          updateConnectionStatus('disconnected', 'Disconnected');
        },

        rejected() {
          console.error('Connection to OrdrChannel was rejected');
          updateConnectionStatus('error', 'Connection rejected');
        },

        received(data) {
          console.log('Received WebSocket message with keys:', Object.keys(data));

          try {
            // STEP 1: Preserve modal state before any DOM updates
            let preservedModals = [];

            // Map WebSocket data keys to their corresponding DOM selectors
            const partialsToUpdate = [
              { key: 'context', selector: '#contextContainer' },
              { key: 'modals', selector: '#modalsContainer' },
              {
                key: 'menuContentStaff',
                selector: '#menuContentContainer',
                // For staff content, we need to check if we're in staff mode
                shouldUpdate: () => document.getElementById('menuu') !== null,
              },
              {
                key: 'menuContentCustomer',
                selector: '#menuContentContainer',
                // For customer content, we check if we're in customer mode
                shouldUpdate: () => document.getElementById('menuc') !== null,
              },
              {
                key: 'orderCustomer',
                selector: '#openOrderContainer',
                shouldUpdate: () => document.getElementById('menuc') !== null,
              },
              {
                key: 'orderStaff',
                selector: '#openOrderContainer',
                shouldUpdate: () => document.getElementById('menuu') !== null,
              },
              {
                key: 'tableLocaleSelectorStaff',
                selector: '#tableLocaleSelectorContainer',
                shouldUpdate: () => document.getElementById('menuu') !== null,
              },
              {
                key: 'tableLocaleSelectorCustomer',
                selector: '#tableLocaleSelectorContainer',
                shouldUpdate: () => document.getElementById('menuc') !== null,
              },
            ];

            // Update each partial if it exists in the data and should be updated
            partialsToUpdate.forEach(({ key, selector, shouldUpdate }) => {
              // Skip if the key doesn't exist in the data or shouldn't be updated
              if (!data[key] || (shouldUpdate && !shouldUpdate())) {
                return;
              }
              
              // Skip updating modals if we're closing the add item modal
              if (key === 'modals' && window.closingAddItemModal) {
                console.log('[Modal Update] Skipping modal update - addItemToOrderModal is closing');
                return;
              }

              console.log(`Updating partial: ${key}`);
              const element = document.querySelector(selector);

              if (element) {
                try {
                  // STEP 2: If updating modals, preserve state first
                  if (key === 'modals') {
                    preservedModals = preserveModalState();
                  }

                  const decompressed = decompressPartial(data[key]);

                  // Special handling for menu content to replace the entire container
                  if (key === 'menuContentStaff' || key === 'menuContentCustomer') {
                    element.innerHTML = decompressed;
                  } else {
                    // For other elements, replace the content
                    element.innerHTML = decompressed;
                  }

                  // STEP 3: If we updated modals, restore state after DOM is ready
                  if (key === 'modals' && preservedModals.length > 0) {
                    // Use setTimeout to ensure DOM is fully updated
                    setTimeout(() => {
                      try {
                        restoreModalState(preservedModals);
                      } catch (restoreError) {
                        console.error(
                          '[Modal Preservation] Failed to restore modals, using fallback:',
                          restoreError
                        );
                        closeAllModalsProper();
                      }
                    }, 100);
                  }

                  console.log(`Updated ${key} with ${decompressed.length} characters`);
                } catch (error) {
                  console.error(`Error processing ${key}:`, error);
                  // If modal update failed, ensure cleanup
                  if (key === 'modals') {
                    closeAllModalsProper();
                  }
                }
              } else {
                console.warn(`Element not found for selector: ${selector} (key: ${key})`);
              }
            });

            // Handle full page refresh if needed
            if (data.fullPageRefresh && data.fullPageRefresh.refresh === true) {
              console.log('Full page refresh requested');
              window.location.reload();
            }

            // Refresh any order-related logic
            refreshOrderJSLogic();
            
            // Dispatch custom event for test synchronization
            // Tests can wait for this event instead of arbitrary sleeps
            window.dispatchEvent(new CustomEvent('ordr:updated', { 
              detail: { 
                keys: Object.keys(data),
                timestamp: new Date().getTime()
              }
            }));
            
            // Also dispatch specific events for different update types
            if (data.menuContentStaff || data.menuContentCustomer) {
              window.dispatchEvent(new CustomEvent('ordr:menu:updated', { 
                detail: { timestamp: new Date().getTime() }
              }));
            }
            if (data.orderStaff || data.orderCustomer) {
              window.dispatchEvent(new CustomEvent('ordr:order:updated', { 
                detail: { timestamp: new Date().getTime() }
              }));
            }
            if (data.modals) {
              window.dispatchEvent(new CustomEvent('ordr:modals:updated', { 
                detail: { timestamp: new Date().getTime() }
              }));
            }
          } catch (error) {
            console.error('Error processing received data:', error);
            updateConnectionStatus('error', 'Error processing update');
          }
        },
      }
    );

    return subscription;
  };

  // Initial subscription
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
    document.addEventListener('DOMContentLoaded', initializeOrderChannel);
  } else {
    initializeOrderChannel();
  }
}
