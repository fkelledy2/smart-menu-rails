export function initOrders() {
  // Define utility functions first
  function post(url, body) {
    $('#orderCart').hide();
    $('#orderCartSpinner').show();

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    if (!csrfToken) {
      console.error('CSRF token not found');
    }

    return fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': csrfToken || '',
      },
      body: JSON.stringify(body),
    })
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Network response was not ok.');
      })
      .then((data) => {
        console.log('Success:', data);
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
        return data;
      })
      .catch((error) => {
        console.error('Error:', error);
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
        throw error;
      });
  }

  function patch(url, body) {
    $('#orderCart').hide();
    $('#orderCartSpinner').show();
    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: JSON.stringify(body),
    })
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Network response was not ok.');
      })
      .then((data) => {
        console.log('PATCH Success:', data);
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
      })
      .catch((error) => {
        console.error('PATCH Error:', error);
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
      });
  }

  function del(url) {
    $('#orderCart').hide();
    $('#orderCartSpinner').show();
    fetch(url, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
    })
      .then((response) => {
        if (response.ok) {
          console.log('DELETE Success');
        } else {
          throw new Error('Network response was not ok.');
        }
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
      })
      .catch((error) => {
        console.error('DELETE Error:', error);
        $('#orderCartSpinner').hide();
        $('#orderCart').show();
      });
  }

  const locationReload = false;

  const ORDR_OPENED = 0;
  const ORDR_ORDERED = 20;
  const ORDR_DELIVERED = 25;
  const ORDR_BILLREQUESTED = 30;
  const ORDR_CLOSED = 40;

  const ORDRITEM_ADDED = 0;
  const ORDRITEM_REMOVED = 10;
  const ORDRITEM_ORDERED = 20;
  const ORDRITEM_PREPARED = 30;
  const ORDRITEM_DELIVERED = 40;

  let restaurantCurrencySymbol = '$';

  // --- Robust resolvers for dynamic IDs (DOM may re-render) ---
  function getRestaurantId() {
    const fromHidden = document.getElementById('currentRestaurant')?.textContent?.trim();
    if (fromHidden) return fromHidden;
    const fromContext = document.querySelector('#contextContainer')?.dataset?.restaurantId;
    if (fromContext) return fromContext;
    const fromBody = document.body?.dataset?.restaurantId;
    if (fromBody) return fromBody;
    const any = document.querySelector('[data-restaurant-id]')?.dataset?.restaurantId;
    if (any) return any;
    return null;
  }
  function getCurrentOrderId() {
    const fromHidden = document.getElementById('currentOrder')?.textContent?.trim();
    if (fromHidden) return fromHidden;
    const fromPay = document.getElementById('openOrderId')?.value?.trim();
    if (fromPay) return fromPay;
    return null;
  }

  // Resolve current table id from context partials
  function getCurrentTableId() {
    const fromHidden = document.getElementById('currentTable')?.textContent?.trim();
    if (fromHidden) return fromHidden;
    return null;
  }

  // Resolve current menu id from context partials
  function getCurrentMenuId() {
    const fromHidden = document.getElementById('currentMenu')?.textContent?.trim();
    if (fromHidden) return fromHidden;
    return null;
  }

  if (document.getElementById('openOrderModalLabel')) {
    document.getElementById('openOrderModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('openOrderModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('addItemToOrderModalLabel')) {
    document.getElementById('addItemToOrderModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('addItemToOrderModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('filterOrderModalLabel')) {
    document.getElementById('filterOrderModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('filterOrderModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('viewOrderModalLabel')) {
    document.getElementById('viewOrderModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('viewOrderModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('requestBillModalLabel')) {
    document.getElementById('requestBillModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('requestBillModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('payOrderModalLabel')) {
    document.getElementById('payOrderModalLabel').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('payOrderModalLabel').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }
  if (document.getElementById('addNameToParticipantModal')) {
    document.getElementById('addNameToParticipantModal').addEventListener('shown.bs.modal', () => {
      document.getElementById('backgroundContent').setAttribute('inert', '');
    });
    document.getElementById('addNameToParticipantModal').addEventListener('hidden.bs.modal', () => {
      document.getElementById('backgroundContent').removeAttribute('inert');
    });
  }

  function refreshOrderJSLogic() {
    // Table selector: search filter (idempotent)
    (function bindTableSelectorSearch() {
      const menuEl = document.querySelector('.table-dropdown-menu');
      const input = document.getElementById('table-selector-search');
      if (!menuEl || !input) return;
      if (input.__bound) return; // idempotency guard
      input.__bound = true;

      const items = Array.from(menuEl.querySelectorAll('li > a.dropdown-item'));
      const getText = (a) => (a.getAttribute('data-filter-text') || a.textContent || '').toLowerCase();
      const liFromA = (a) => a.closest('li');
      const debounce = (fn, ms) => { let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); }; };

      const applyFilter = (q) => {
        const query = (q || '').trim().toLowerCase();
        if (!query) {
          items.forEach((a) => { const li = liFromA(a); if (li) li.style.display = ''; });
          return;
        }
        items.forEach((a) => {
          const li = liFromA(a);
          if (!li) return;
          const text = getText(a);
          li.style.display = text.includes(query) ? '' : 'none';
        });
      };

      input.addEventListener('input', debounce((e) => applyFilter(e.target.value), 180));
    })();
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
        // Disable if outside time window or order not active
        if (!(currentOffset >= fromOffeset && currentOffset <= toOffeset) || !canAdd) {
          $(this).attr('disabled', 'disabled');
        } else {
          $(this).removeAttr('disabled');
        }
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
        const isTasting = addItemToOrderModal?.dataset?.tasting === 'true';
        const button = event.relatedTarget;
        if (!button) {
          // Modal opened programmatically (e.g., tasting). Fields already set; nothing to pull from button.
          return;
        }
        // Standard flow: populate from triggering button attributes
        const getAttr = (name) => button.getAttribute(name);
        const priceAttr = getAttr('data-bs-menuitem_price');
        $('#a2o_ordr_id').text(getAttr('data-bs-ordr_id'));
        $('#a2o_menuitem_id').text(getAttr('data-bs-menuitem_id'));
        $('#a2o_menuitem_name').text(getAttr('data-bs-menuitem_name'));
        if (priceAttr) {
          $('#a2o_menuitem_price').text(parseFloat(priceAttr).toFixed(2));
        }
        $('#a2o_menuitem_description').text(getAttr('data-bs-menuitem_description'));
        try {
          const imageElement = addItemToOrderModal.querySelector('#a2o_menuitem_image');
          if (imageElement) {
            imageElement.src = getAttr('data-bs-menuitem_image');
            imageElement.alt = getAttr('data-bs-menuitem_name');
          }
        } catch (err) {
          console.log(err);
        }

        // Alcohol Phase 1: capture alcoholic flag and provide staff reminder
        const alcoholicFlag = getAttr('data-bs-menuitem_alcoholic') === '1';
        if (alcoholicFlag) {
          addItemToOrderModal.dataset.alcoholic = '1';
        } else {
          delete addItemToOrderModal.dataset.alcoholic;
        }

        // Non-blocking reminder for staff if alcoholic
        try {
          const isStaff = !!document.getElementById('currentEmployee');
          const modalBody = addItemToOrderModal.querySelector('.modal-body');
          if (isStaff && alcoholicFlag && modalBody) {
            if (!addItemToOrderModal.querySelector('.alcohol-age-reminder')) {
              const note = document.createElement('div');
              note.className = 'alcohol-age-reminder alert alert-warning py-2 px-3 mb-2';
              note.role = 'alert';
              note.textContent = (document.getElementById('alcoholVerifyAgeText')?.textContent || 'Contains alcohol — verify legal age where applicable.');
              modalBody.prepend(note);
            }
          } else {
            const existing = addItemToOrderModal.querySelector('.alcohol-age-reminder');
            if (existing) existing.remove();
          }
        } catch (_) {}
      });
      $('#addItemToOrderButton').on('click', async function (evt) {
        console.log('[A2O] Confirm clicked');
        const addModalEl = document.getElementById('addItemToOrderModal');
        const isTasting = addModalEl && addModalEl.dataset && addModalEl.dataset.tasting === 'true';
        if (isTasting) {
          if (window.__tastingPosting) {
            console.warn('[TASTING] Post already in progress, skipping duplicate');
            return false;
          }
          window.__tastingPosting = true;
          try {
            const restaurantId = getRestaurantId();
            const ordrId = getCurrentOrderId();
            const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
            if (!restaurantId || !ordrId || !statusStr || statusStr === 'billrequested' || statusStr === 'closed') {
              console.error('[TASTING] Order not active or status not allowed.');
              return false;
            }
            let base = {};
            try {
              base = JSON.parse(addModalEl.dataset.tastingBase || '{}');
            } catch (e) {
              console.error('[TASTING] Invalid tasting base payload:', e);
              return false;
            }
            const qtyField = addModalEl.querySelector('#a2o_tasting_qty');
            const pairingField = addModalEl.querySelector('#a2o_tasting_pairing');
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

            console.log('[TASTING] Posting lines:', lines);
            const requests = lines.map((l) => ({
              ordritem: {
                ordr_id: ordrId,
                menuitem_id: l.menuitem_id,
                status: ORDRITEM_ADDED,
                ordritemprice: Number(l.price).toFixed(2),
              },
            }));
            Promise.all(requests.map((payload) => post(`/restaurants/${restaurantId}/ordritems`, payload)))
              .then(() => {
                // Clear tasting flags and hide modal
                delete addModalEl.dataset.tasting;
                delete addModalEl.dataset.tastingBase;
                if (addModalEl && window.bootstrap && window.bootstrap.Modal) {
                  const modalInstance = window.bootstrap.Modal.getInstance(addModalEl) || window.bootstrap.Modal.getOrCreateInstance(addModalEl);
                  modalInstance.hide();
                }
              })
              .finally(() => {
                window.__tastingPosting = false;
              })
              .catch((e) => console.error('[TASTING] Post failed:', e));
            return false;
          } catch (e) {
            console.error('[TASTING] Unexpected error:', e);
            return false;
          }
        }
        // Gate: require active order before posting; if not, prompt Start Order
        const currentOrderId = document.getElementById('currentOrder')?.textContent?.trim();
        const currentStatus = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
        const canAdd = !!currentOrderId && !!currentStatus && currentStatus !== 'billrequested' && currentStatus !== 'closed';
        if (!canAdd) {
          // Close add modal and open Start Order modal if available
          if (addModalEl && window.bootstrap && window.bootstrap.Modal) {
            const addInst = window.bootstrap.Modal.getInstance(addModalEl) || window.bootstrap.Modal.getOrCreateInstance(addModalEl);
            addInst.hide();
          }
          const openOrderModal = document.getElementById('openOrderModal');
          if (openOrderModal && window.bootstrap && window.bootstrap.Modal) {
            const openInst = window.bootstrap.Modal.getInstance(openOrderModal) || window.bootstrap.Modal.getOrCreateInstance(openOrderModal);
            openInst.show();
          }
          evt.preventDefault();
          return false;
        }

        // Alcohol Phase 1: block alcoholic items if restaurant does not allow alcohol
        try {
          const allowAlcohol = document.getElementById('currentRestaurantAllowAlcohol')?.textContent === '1';
          const isAlcoholicItem = !!(addModalEl && addModalEl.dataset && addModalEl.dataset.alcoholic === '1');
          if (isAlcoholicItem && !allowAlcohol) {
            // Non-blocking UX: disable action and show message
            alert(document.getElementById('alcoholSalesDisabledText')?.textContent || 'Alcohol sales are disabled for this restaurant.');
            evt.preventDefault();
            return false;
          }
          // Phase 2: time/day policy enforcement
          const allowedNow = document.getElementById('alcoholAllowedNow')?.textContent === '1';
          if (isAlcoholicItem && allowAlcohol && !allowedNow) {
            alert(document.getElementById('alcoholPolicyBlockedText')?.textContent || 'Alcohol not available at this time.');
            evt.preventDefault();
            return false;
          }
        } catch (_) {}

        // Debug: Check if required elements exist
        const ordrId = $('#a2o_ordr_id').text() || currentOrderId;
        const menuitemId = $('#a2o_menuitem_id').text();
        const price = $('#a2o_menuitem_price').text();
        const restaurantId = $('#currentRestaurant').text();

        console.log('Order Item Debug:', {
          ordrId: ordrId,
          menuitemId: menuitemId,
          price: price,
          restaurantId: restaurantId,
          status: ORDRITEM_ADDED,
        });

        // Check for missing required data
        if (!ordrId || !menuitemId || !restaurantId) {
          console.error('Missing required data for order item creation');
          return false;
        }

        const ordritem = {
          ordritem: {
            ordr_id: ordrId,
            menuitem_id: menuitemId,
            status: ORDRITEM_ADDED,
            ordritemprice: price,
          },
        };

        console.log('Sending order item:', ordritem);
        
        // Post the order item first
        post(`/restaurants/${restaurantId}/ordritems`, ordritem)
          .then(() => {
            console.log('Order item posted successfully');
            
            // Set flag to prevent WebSocket from updating modals while closing
            window.closingAddItemModal = true;
            
            // Close the modal (Bootstrap 5 API only; avoid jQuery plugin)
            const modalEl = document.getElementById('addItemToOrderModal');
            if (modalEl && window.bootstrap && window.bootstrap.Modal) {
              const modalInstance = window.bootstrap.Modal.getInstance(modalEl) || window.bootstrap.Modal.getOrCreateInstance(modalEl);
              modalInstance.hide();
            }
            
            // Clear flag after a delay (modal animation is ~300ms)
            setTimeout(() => {
              window.closingAddItemModal = false;
            }, 500);
          })
          .catch((error) => {
            console.error('Error adding item to order:', error);
            window.closingAddItemModal = false;
          });
        
        return false; // Prevent any default behavior
      });
    }
    if ($('#start-order').length) {
      $(document).off('click.startOrder').on('click.startOrder', '#start-order:not([disabled])', function (evt) {
        try {
          evt.preventDefault();
          evt.stopPropagation();
        } catch (_) {}
        const btn = this;
        btn.setAttribute('disabled', 'disabled');
        const ordercapacity = document.getElementById('orderCapacity')?.value || 1;
        const restaurantId = getRestaurantId();
        const tablesettingId = getCurrentTableId();
        const menuId = getCurrentMenuId();
        if (!restaurantId || !tablesettingId || !menuId) {
          console.warn('[StartOrder] Missing required ids; aborting', { restaurantId, tablesettingId, menuId });
          alert('Please select a table before starting an order.');
          btn.removeAttribute('disabled');
          return false;
        }
        const payload = {
          ordr: {
            tablesetting_id: tablesettingId,
            restaurant_id: restaurantId,
            menu_id: menuId,
            ordercapacity: ordercapacity,
            status: ORDR_OPENED,
          },
        };
        if ($('#currentEmployee').length) {
          payload.ordr.employee_id = $('#currentEmployee').text();
        }
        post(`/restaurants/${restaurantId}/ordrs`, payload)
          .then(() => {
            // Close modal programmatically to avoid Bootstrap backdrop issues
            const modalEl = document.getElementById('openOrderModal');
            if (modalEl && window.bootstrap && window.bootstrap.Modal) {
              const inst = window.bootstrap.Modal.getInstance(modalEl) || window.bootstrap.Modal.getOrCreateInstance(modalEl);
              inst.hide();
            }
          })
          .finally(() => {
            btn.removeAttribute('disabled');
          });
        return false;
      });
    }
    if ($('#pay-order').length) {
      $(document).off('click.payOrder').on('click.payOrder', '#pay-order:not([disabled])', function () {
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

    // Tasting Menu: delegate handlers (customer and staff views)
    window.bindTastingCTAs = function bindTastingCTAs() {
      // Update enabled state for all tasting CTAs
      const updateAll = () => {
        const ordrId = document.getElementById('currentOrder')?.textContent?.trim();
        const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
        const canAdd = !!ordrId && !!statusStr && statusStr !== 'billrequested' && statusStr !== 'closed';
        document.querySelectorAll('[data-tasting-meta] .tasting-cta').forEach((btn) => {
          if (canAdd) btn.removeAttribute('disabled'); else btn.setAttribute('disabled', 'disabled');
        });
      };
      updateAll();
      window.addEventListener('ordr:updated', updateAll);
    };

    // Delegated click handler so it survives partial refreshes
    if (!window.__tastingDelegationBound) {
      window.__tastingDelegationBound = true;
      document.addEventListener('click', (ev) => {
        const btn = ev.target.closest?.('.tasting-cta');
        if (!btn) return;
        const container = btn.closest('[data-tasting-meta]');
        if (!container) return;
        try {
          console.log('[TASTING] CTA clicked');
          const meta = JSON.parse(container.getAttribute('data-tasting-meta'));
          const restaurantId = getRestaurantId();
          const ordrId = getCurrentOrderId();
          const statusStr = document.getElementById('currentOrderStatus')?.textContent?.trim()?.toLowerCase();
          if (!restaurantId || !ordrId || !statusStr || statusStr === 'billrequested' || statusStr === 'closed') {
            console.error('Missing restaurant or order id');
            return;
          }
          const optionalToggles = Array.from(document.querySelectorAll('.tasting-optional-toggle'));
          const uncheckedOptionalIds = new Set(optionalToggles.filter((el) => !el.checked).map((el) => parseInt(el.getAttribute('data-menuitem-id'))));
          const items = meta.items || [];
          const activeItems = items.filter((it) => !uncheckedOptionalIds.has(it.id));
          const tastingPrice = (meta.tasting_price_cents || 0) / 100.0;
          const pairingPrice = (meta.pairing_price_cents || 0) / 100.0;
          if (activeItems.length === 0 && items.length > 0) activeItems.push(items[0]);
          const carrierMenuitemId = meta.carrier_id || activeItems[0]?.id || items[0]?.id;
          if (!carrierMenuitemId) { console.error('No items available to carry tasting base'); return; }

          const addModal = document.getElementById('addItemToOrderModal');
          if (!addModal) return;
          const name = meta.section_name || 'Tasting Menu';
          const description = 'Tasting menu bundle';
          const setText = (sel, text) => { const el = addModal.querySelector(sel); if (el) el.textContent = text; };
          setText('#a2o_ordr_id', ordrId);
          setText('#a2o_menuitem_id', carrierMenuitemId);
          setText('#a2o_menuitem_name', name);
          setText('#a2o_menuitem_description', description);
          const controlsWrap = addModal.querySelector('#a2o_tasting_controls');
          const pairingWrap = addModal.querySelector('#a2o_tasting_pairing_wrap');
          const qtyField = addModal.querySelector('#a2o_tasting_qty');
          const qtyIncr = addModal.querySelector('#a2o_tasting_qty_incr');
          const qtyDecr = addModal.querySelector('#a2o_tasting_qty_decr');
          const pairingField = addModal.querySelector('#a2o_tasting_pairing');
          if (controlsWrap) controlsWrap.hidden = false;
          if (pairingWrap) pairingWrap.hidden = !meta.allow_pairing;
          if (qtyField) qtyField.value = 1;
          if (pairingField) pairingField.checked = false;
          const computeTotal = (q, includePairing) => {
            const baseMultiplier = meta.price_per === 'table' ? 1 : q;
            const baseTotal = tastingPrice * baseMultiplier;
            let sum = baseTotal > 0 ? baseTotal : 0;
            if (includePairing && meta.allow_pairing && pairingPrice > 0) { sum += pairingPrice * q; }
            activeItems.forEach((it) => { const supp = (it.supplement_cents || 0) / 100.0; if (supp > 0) sum += supp * q; });
            return sum;
          };
          const updatePrice = () => {
            const q = Math.max(1, parseInt(qtyField?.value || '1'));
            const total = computeTotal(q, !!pairingField?.checked);
            setText('#a2o_menuitem_price', total.toFixed(2));
          };
          qtyIncr?.addEventListener('click', () => { if (!qtyField) return; qtyField.value = Math.max(1, parseInt(qtyField.value || '1')) + 1; updatePrice(); });
          qtyDecr?.addEventListener('click', () => { if (!qtyField) return; const q = Math.max(1, parseInt(qtyField.value || '1')); qtyField.value = q > 1 ? q - 1 : 1; updatePrice(); });
          qtyField?.addEventListener('input', updatePrice);
          pairingField?.addEventListener('change', updatePrice);
          updatePrice();
          addModal.dataset.tasting = 'true';
          addModal.dataset.tastingBase = JSON.stringify({
            section_name: name,
            price_per: meta.price_per,
            tasting_price: tastingPrice,
            pairing_price: pairingPrice,
            allow_pairing: !!meta.allow_pairing,
            carrier_id: carrierMenuitemId,
            active_items: activeItems.map(it => ({ id: it.id, supplement_cents: it.supplement_cents }))
          });
          if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const instance = bootstrap.Modal.getInstance(addModal) || new bootstrap.Modal(addModal);
            instance.show();
          }
        } catch (e) {
          console.error('Failed to prepare tasting bundle:', e);
        }
      });
    }

    // Bind on initial load
    window.bindTastingCTAs();
    // Re-bind/refresh after websocket menu content updates
    window.addEventListener('ordr:menu:updated', () => { window.bindTastingCTAs(); });
  }

  refreshOrderJSLogic();

  if ($('#restaurantTabs').length) {
    function linkOrdr(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').id;
      const restaurantId = $('#currentRestaurant').text();
      return (
        "<a class='link-dark' href='/restaurants/" +
        restaurantId +
        '/ordrs/' +
        id +
        "'>" +
        rowData +
        '</a>'
      );
    }
    function linkMenu(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').menu.name;
      return rowData;
    }
    function linkTablesetting(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').tablesetting.name;
      return rowData;
    }
    const ordrTableElement = document.getElementById('restaurant-ordr-table');
    if (!ordrTableElement) return; // Exit if element doesn't exist
    const restaurantId = ordrTableElement.getAttribute('data-bs-restaurant_id');
    const restaurantOrdrTable = new Tabulator('#restaurant-ordr-table', {
      pagination: true, //enable.
      paginationSize: 10, // this option can take any positive integer value
      dataLoader: false,
      maxHeight: '100%',
      responsiveLayout: true,
      layout: 'fitColumns',
      ajaxURL: '/restaurants/' + restaurantId + '/ordrs.json',
      initialSort: [
        { column: 'ordrDate', dir: 'desc' },
        { column: 'id', dir: 'desc' },
      ],
      columns: [
        {
          title: 'Id',
          field: 'id',
          formatter: linkOrdr,
          frozen: true,
          responsive: 0,
          hozAlign: 'left',
        },
        { title: 'Menu', field: 'menu.id', formatter: linkMenu, responsive: 0, hozAlign: 'left' },
        {
          title: 'Table',
          field: 'tablesetting.id',
          formatter: linkTablesetting,
          responsive: 4,
          hozAlign: 'left',
        },
        { title: 'Status', field: 'status', responsive: 4, hozAlign: 'left' },
        {
          title: 'Nett',
          field: 'nett',
          formatter: 'money',
          hozAlign: 'right',
          responsive: 5,
          headerHozAlign: 'right',
          formatterParams: {
            decimal: '.',
            thousand: ',',
            symbol: restaurantCurrencySymbol,
            negativeSign: true,
            precision: 2,
          },
        },
        {
          title: 'Service',
          field: 'service',
          formatter: 'money',
          hozAlign: 'right',
          responsive: 5,
          headerHozAlign: 'right',
          formatterParams: {
            decimal: '.',
            thousand: ',',
            symbol: restaurantCurrencySymbol,
            negativeSign: true,
            precision: 2,
          },
        },
        {
          title: 'Tax',
          field: 'tax',
          formatter: 'money',
          hozAlign: 'right',
          responsive: 5,
          headerHozAlign: 'right',
          formatterParams: {
            decimal: '.',
            thousand: ',',
            symbol: restaurantCurrencySymbol,
            negativeSign: true,
            precision: 2,
          },
        },
        {
          title: 'Gross',
          field: 'gross',
          formatter: 'money',
          hozAlign: 'right',
          responsive: 0,
          headerHozAlign: 'right',
          formatterParams: {
            decimal: '.',
            thousand: ',',
            symbol: restaurantCurrencySymbol,
            negativeSign: true,
            precision: 2,
          },
        },
        {
          title: 'Date',
          field: 'ordrDate',
          responsive: 0,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
      ],
      locale: true,
      langs: {
        it: {
          columns: {
            id: 'ID',
            'menu.id': 'Menu',
            'tablesetting.id': 'Tavolo',
            status: 'Stato',
            nett: 'Tetto',
            service: 'Servizio',
            tax: 'Tassare',
            gross: 'Totale',
            ordrDate: 'Data',
          },
        },
        en: {
          columns: {
            id: 'ID',
            'menu.id': 'Menu',
            'tablesetting.id': 'Table',
            status: 'Status',
            nett: 'nett',
            service: 'Service',
            tax: 'Tax',
            gross: 'Gross',
            ordrDate: 'Date',
          },
        },
      },
    });
  }

  function fetchQR(paymentUrl) {
    const qrCode = new QRCodeStyling({
      type: 'canvas',
      shape: 'square',
      width: 200,
      height: 200,
      data: paymentUrl,
      margin: 0,
      qrOptions: {
        typeNumber: '0',
        mode: 'Byte',
        errorCorrectionLevel: 'Q',
      },
      imageOptions: {
        saveAsBlob: true,
        hideBackgroundDots: true,
        imageSize: 0.4,
        margin: 0,
      },
      dotsOptions: {
        type: 'extra-rounded',
        color: '#000000',
        roundSize: true,
      },
      backgroundOptions: {
        round: 0,
        color: '#ffffff',
      },
      image: $('#qrIcon').text(),
      dotsOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#6a1a4c',
          color2: '#6a1a4c',
          rotation: '0',
        },
      },
      cornersSquareOptions: {
        type: 'extra-rounded',
        color: '#000000',
      },
      cornersSquareOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      cornersDotOptions: {
        type: '',
        color: '#000000',
      },
      cornersDotOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      backgroundOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#ffffff',
          color2: '#ffffff',
          rotation: '0',
        },
      },
    });
    document.getElementById('paymentQR').innerHTML = '';
    qrCode.append(document.getElementById('paymentQR'));
  }

  const tableElement = document.getElementById('dw-orders-mv-table');
  const loadingElement = document.getElementById('tabulator-loading');
  if (!tableElement || !loadingElement) return;

  showLoading();
  fetchData()
    .then((data) => {
      hideLoading();
      if (!data || data.length === 0) {
        tableElement.innerHTML = '<div class="alert alert-info">No data found.</div>';
        return;
      }
      renderTable(tableElement, data);
    })
    .catch((error) => {
      hideLoading();
      tableElement.innerHTML = '<div class="alert alert-danger">Failed to load data.</div>';
    });

  function showLoading() {
    loadingElement.style.display = 'block';
  }

  function hideLoading() {
    loadingElement.style.display = 'none';
  }

  function fetchData() {
    const url = tableElement.getAttribute('data-json-url');
    return fetch(url).then((response) => response.json());
  }

  function renderTable(element, data) {
    const columns = Object.keys(data[0]).map((key) => ({
      title: key.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase()),
      field: key,
      headerFilter: true,
    }));
    columns.push({
      title: 'Actions',
      formatter: function (cell, formatterParams, onRendered) {
        const id = cell.getRow().getData().id;
        return id ? `<a href='/dw_orders_mv/${id}'>Show</a>` : '';
      },
    });
    new Tabulator(element, {
      data: data,
      layout: 'fitDataTable',
      columns: columns,
      movableColumns: true,
    });
  }
}
