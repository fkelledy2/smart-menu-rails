import { Controller } from '@hotwired/stimulus';
import { DirectUpload } from '@rails/activestorage';
import { Modal } from 'bootstrap';

export default class extends Controller {
  static targets = [
    'confirmModal',
    'confirmButton',
    'confirmSyncCheckbox',
    'confirmStatus',
    'confirmError',
    'editItemModal',
    'editItemForm',
    'editItemId',
    'editItemName',
    'editItemDescription',
    'editItemPrice',
    'editItemSection',
    'editItemAllergens',
    'editItemVegetarian',
    'editItemVegan',
    'editItemGlutenFree',
    'editItemDairyFree',
    'editItemNutFree',
    'overallPercent',
    'overallSlider',
    'overallFill',
    'phaseText',
    'pageText',
    'phasePercent',
  ];

  static values = {
    progressUrl: String,
  };

  connect() {
    // Initialize modals
    if (this.hasConfirmModalTarget) {
      this.confirmModal = new Modal(this.confirmModalTarget);
    }

    if (this.hasEditItemModalTarget) {
      this.editItemModal = new Modal(this.editItemModalTarget);
    }

    // Add event listener for keyboard shortcuts
    document.addEventListener('keydown', this.handleKeyDown.bind(this));

    this.progressTimer = null;
    this.startProgressPolling();
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleKeyDown.bind(this));
    this.stopProgressPolling();
  }

  startProgressPolling() {
    if (!this.hasProgressUrlValue) return;
    if (this.progressTimer) return;

    const statusBadge = document.querySelector('.card-header .badge');
    const statusText = (statusBadge && statusBadge.textContent) ? statusBadge.textContent.toLowerCase() : '';
    const shouldPoll = statusText.includes('processing') || statusText.includes('pending');
    if (!shouldPoll) return;

    const tick = async () => {
      try {
        const res = await fetch(this.progressUrlValue, { headers: { Accept: 'application/json' }, credentials: 'same-origin' });
        if (!res.ok) return;
        const data = await res.json();
        this.applyProgress(data);

        if (data.status === 'completed') {
          this.onImportCompleted();
        }
        if (data.status === 'failed') {
          this.stopProgressPolling();
        }
      } catch (_) {
      }
    };

    tick();
    this.progressTimer = window.setInterval(tick, 2000);
  }

  stopProgressPolling() {
    if (this.progressTimer) {
      window.clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  applyProgress(data) {
    const percent = Number(data.percent || 0);

    if (this.hasOverallPercentTarget) this.overallPercentTarget.textContent = `${Math.round(percent)}%`;
    if (this.hasOverallSliderTarget) this.overallSliderTarget.value = String(Math.round(percent));
    if (this.hasOverallFillTarget) this.overallFillTarget.style.width = `${Math.round(percent)}%`;

    const phase = String(data.phase || '').toLowerCase();

    if (this.hasPhaseTextTarget) {
      if (phase === 'extracting_pages') {
        this.phaseTextTarget.textContent = 'Extracting PDF pages…';
      } else if (phase === 'parsing_menu') {
        this.phaseTextTarget.textContent = 'Parsing menu structure…';
      } else if (phase === 'saving_menu') {
        this.phaseTextTarget.textContent = 'Saving menu items…';
      }
    }

    if (this.hasPageTextTarget && data.pages) {
      const p = data.pages;
      const total = p.total == null ? '?' : p.total;
      const processed = p.processed == null ? 0 : p.processed;
      this.pageTextTarget.textContent = `Page ${processed} of ${total}`;
    }

    if (this.hasPhasePercentTarget) {
      if (phase === 'saving_menu' && data.parsing) {
        const parsed = data.parsing.items_processed || 0;
        const total = data.parsing.items_total || 0;
        if (total > 0) {
          this.phasePercentTarget.textContent = `${Math.round(data.parsing.percent || 0)}% (${parsed}/${total} items)`;
        } else {
          this.phasePercentTarget.textContent = `${Math.round(percent)}%`;
        }
      } else {
        this.phasePercentTarget.textContent = `${Math.round(percent)}%`;
      }
    }
  }

  onImportCompleted() {
    this.stopProgressPolling();

    try {
      if (this.confirmModal) this.confirmModal.hide();
    } catch (_) {}

    window.location.reload();
  }

  handleKeyDown(event) {
    // Close modals with Escape key
    if (event.key === 'Escape') {
      if (this.hasConfirmModalTarget && !this.confirmModalTarget.classList.contains('hidden')) {
        this.hideConfirmModal();
      }
      if (this.hasEditItemModalTarget && !this.editItemModalTarget.classList.contains('hidden')) {
        this.hideEditItemModal();
      }
    }
  }

  // Confirmation Modal Methods
  showConfirmModal() {
    if (this.hasConfirmModalTarget) {
      this.confirmModal.show();
    }
  }

  hideConfirmModal() {
    if (this.hasConfirmModalTarget) {
      this.confirmModal.hide();
    }
  }

  submitForm() {
    // This will be called when the user confirms the import
    // The form submission is handled by Rails via the button_to helper
    // This method is just a placeholder for any additional client-side logic
  }

  // Edit Item Modal Methods
  showEditItemModal(event) {
    if (!this.hasEditItemModalTarget) return;

    const itemId = event.currentTarget.dataset.itemId;
    const itemName = event.currentTarget.dataset.itemName || '';
    const itemDescription = event.currentTarget.dataset.itemDescription || '';
    const itemPrice = event.currentTarget.dataset.itemPrice || '';
    const itemSection = event.currentTarget.dataset.itemSection || '';

    // Parse allergens and dietary restrictions from data attributes
    let allergens = [];
    try {
      allergens = JSON.parse(event.currentTarget.dataset.itemAllergens || '[]');
    } catch (e) {
      console.error('Error parsing allergens:', e);
    }

    let dietaryRestrictions = [];
    try {
      dietaryRestrictions = JSON.parse(event.currentTarget.dataset.itemDietaryRestrictions || '[]');
    } catch (e) {
      console.error('Error parsing dietary restrictions:', e);
    }

    // Set form values
    this.editItemIdTarget.value = itemId;
    this.editItemNameTarget.value = itemName;
    this.editItemDescriptionTarget.value = itemDescription;
    this.editItemPriceTarget.value = itemPrice;
    if (this.hasEditItemSectionTarget) this.editItemSectionTarget.value = itemSection;

    // Set allergens (TomSelect if present, fallback to native/jQuery)
    if (this.hasEditItemAllergensTarget) {
      const el = this.editItemAllergensTarget;
      if (el.tomselect) {
        try {
          el.tomselect.setValue(allergens, true);
        } catch (e) {
          console.warn('TomSelect setValue failed, falling back:', e);
          el.value = '';
        }
      } else if (window.$) {
        try {
          $(el).val(allergens).trigger('change');
        } catch (_) {}
      } else {
        // native multi-select
        Array.from(el.options).forEach((opt) => (opt.selected = allergens.includes(opt.value)));
      }
    }

    // Set dietary restrictions checkboxes
    this.setDietaryRestrictionCheckbox('vegetarian', dietaryRestrictions);
    this.setDietaryRestrictionCheckbox('vegan', dietaryRestrictions);
    this.setDietaryRestrictionCheckbox('gluten_free', dietaryRestrictions);
    this.setDietaryRestrictionCheckbox('dairy_free', dietaryRestrictions);
    this.setDietaryRestrictionCheckbox('nut_free', dietaryRestrictions);

    // Store id on modal dataset for save fallback
    try {
      this.editItemModalTarget.dataset.itemId = itemId;
    } catch (_) {}

    // Show the modal
    this.editItemModal.show();
  }

  setDietaryRestrictionCheckbox(type, restrictions) {
    const hasTargetProp = this[`hasEditItem${this.capitalize(type)}Target`];
    if (hasTargetProp) {
      const target = this[`editItem${this.capitalize(type)}Target`];
      if (target) target.checked = restrictions.includes(type);
    }
  }

  hideEditItemModal() {
    if (this.hasEditItemModalTarget) {
      this.editItemModal.hide();
    }
  }

  saveItem(event) {
    console.debug('[menu-import#saveItem] click received');
    if (!this.hasEditItemFormTarget) {
      console.warn('[menu-import#saveItem] No editItemFormTarget found');
      return;
    }

    const form = this.editItemFormTarget;
    const formData = new FormData(form);
    let itemId = formData.get('item_id');
    if (!itemId) {
      // fallback: try read from modal dataset if available
      const modal = this.hasEditItemModalTarget
        ? this.editItemModalTarget
        : document.getElementById('editItemModal');
      if (modal && modal.dataset.itemId) itemId = modal.dataset.itemId;
    }
    if (!itemId) {
      console.error('[menu-import#saveItem] Missing item_id in form');
      alert('Unable to save: missing item id.');
      return;
    }

    // Visual feedback during save
    const btn = event?.currentTarget;
    let origHtml;
    if (btn) {
      origHtml = btn.innerHTML;
      btn.disabled = true;
      btn.innerHTML =
        '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span> Saving…';
    }

    // Get selected allergens (TomSelect if present, else jQuery/native)
    let allergens = [];
    if (this.hasEditItemAllergensTarget) {
      const el = this.editItemAllergensTarget;
      if (el && el.tomselect) {
        try {
          allergens = el.tomselect.getValue() || [];
        } catch (_) {
          allergens = [];
        }
      } else if (window.$ && typeof $(el).val === 'function') {
        try {
          allergens = $(el).val() || [];
        } catch (_) {
          allergens = [];
        }
      } else {
        allergens = Array.from(el?.selectedOptions || []).map((o) => o.value);
      }
    }

    // Get selected dietary restrictions from checkboxes
    const dietaryRestrictions = [];
    if (this.hasEditItemVegetarianTarget && this.editItemVegetarianTarget.checked)
      dietaryRestrictions.push('vegetarian');
    if (this.hasEditItemVeganTarget && this.editItemVeganTarget.checked)
      dietaryRestrictions.push('vegan');
    if (this.hasEditItemGlutenFreeTarget && this.editItemGlutenFreeTarget.checked)
      dietaryRestrictions.push('gluten_free');
    if (this.hasEditItemDairyFreeTarget && this.editItemDairyFreeTarget.checked)
      dietaryRestrictions.push('dairy_free');
    if (this.hasEditItemNutFreeTarget && this.editItemNutFreeTarget.checked)
      dietaryRestrictions.push('nut_free');

    const payload = {
      ocr_menu_item: {
        name: formData.get('item_name'),
        description: formData.get('item_description'),
        price: parseFloat(formData.get('item_price')) || 0,
        allergens: allergens,
        dietary_restrictions: dietaryRestrictions,
      },
    };
    console.debug('[menu-import#saveItem] PATCH /ocr_menu_items/' + itemId, payload);

    // Submit the form via fetch
    fetch(`/ocr_menu_items/${itemId}`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': (
          document.querySelector("meta[name='csrf-token']") ||
          document.querySelector("[name='csrf-token']")
        ).content,
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
      credentials: 'same-origin',
    })
      .then((response) => {
        if (!response.ok) {
          return response.text().then((text) => {
            throw new Error(`HTTP ${response.status}: ${text}`);
          });
        }
        return response.json();
      })
      .then((data) => {
        // Update DOM in-place without reload
        try {
          const item = data.item || {};
          const id = String(item.id || '');
          const row = document.querySelector(`.item-row[data-item-id="${id}"]`);
          if (row) {
            // Update name
            const nameSpan = row.querySelector('.fw-semibold span');
            if (nameSpan && item.name != null) nameSpan.textContent = item.name;

            // Update description block
            let descEl = row.querySelector('.text-muted.small.mb-2');
            const newDesc = item.description || '';
            if (newDesc && !descEl) {
              descEl = document.createElement('div');
              descEl.className = 'text-muted small mb-2';
              // insert after header block
              const header = row.querySelector('.d-flex.justify-content-between');
              if (header && header.parentNode)
                header.parentNode.insertBefore(descEl, header.nextSibling);
            }
            if (descEl) {
              if (newDesc) {
                descEl.textContent = newDesc;
              } else {
                descEl.remove();
              }
            }

            // Update price text node inside the price container (first child text before buttons)
            const priceWrap = row.querySelector('.text-nowrap');
            if (priceWrap && item.price != null) {
              const price = Number(item.price);
              let formatted = '';
              if (!isNaN(price)) {
                // Try to reuse existing currency symbol if present
                let existing = '';
                if (priceWrap.firstChild && priceWrap.firstChild.nodeType === Node.TEXT_NODE) {
                  existing = (priceWrap.firstChild.nodeValue || '').trim();
                }
                const symbolMatch = existing.match(/^[^\d\-\.,]+/);
                const symbol = symbolMatch ? symbolMatch[0] : '';
                const amount = price.toFixed(2);
                formatted = symbol
                  ? `${symbol}${amount}`
                  : new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(
                      price
                    );
              }
              if (!priceWrap.firstChild) priceWrap.appendChild(document.createTextNode(''));
              priceWrap.firstChild.nodeValue = formatted ? formatted + ' ' : '';
            }

            // Update dietary badges (create or refresh)
            const existingBadges = row.querySelector('.item-dietary-badges');
            const dietFlags = {
              vegetarian: !!item.is_vegetarian,
              vegan: !!item.is_vegan,
              gluten_free: !!item.is_gluten_free,
              dairy_free: !!item.is_dairy_free,
              nut_free: !!item.is_nut_free,
            };
            const labels = {
              vegetarian: 'Vegetarian',
              vegan: 'Vegan',
              gluten_free: 'Gluten Free',
              dairy_free: 'Dairy Free',
              nut_free: 'Nut Free',
            };
            const activeKeys = Object.keys(dietFlags).filter((k) => dietFlags[k]);
            let badgeWrap = existingBadges;
            if (!badgeWrap && activeKeys.length) {
              badgeWrap = document.createElement('div');
              badgeWrap.className = 'item-dietary-badges mt-1';
              // insert after description if present, else after header
              const descEl2 = row.querySelector('.text-muted.small.mb-2');
              const header = row.querySelector('.d-flex.justify-content-between');
              const anchor = descEl2 || header;
              if (anchor && anchor.parentNode)
                anchor.parentNode.insertBefore(badgeWrap, anchor.nextSibling);
            }
            if (badgeWrap) {
              badgeWrap.innerHTML = activeKeys
                .map(
                  (k) =>
                    `<span class="badge bg-success-subtle text-success border border-success-subtle me-1">${labels[k]}</span>`
                )
                .join('');
              if (!activeKeys.length) badgeWrap.remove();
            }

            // Update edit trigger data attributes for next open
            const editIcon = row.querySelector('.bi.bi-pencil');
            if (editIcon) {
              editIcon.dataset.itemName = item.name || '';
              editIcon.dataset.itemDescription = item.description || '';
              editIcon.dataset.itemPrice = item.price || '';
              editIcon.dataset.itemAllergens = JSON.stringify(item.allergens || []);
              const diet = [];
              if (item.is_vegetarian) diet.push('vegetarian');
              if (item.is_vegan) diet.push('vegan');
              if (item.is_gluten_free) diet.push('gluten_free');
              if (item.is_dairy_free) diet.push('dairy_free');
              if (item.is_nut_free) diet.push('nut_free');
              editIcon.dataset.itemDietaryRestrictions = JSON.stringify(diet);
            }
          }
        } catch (e) {
          console.warn('DOM update after save failed:', e);
        }

        // Close the modal after updating
        this.hideEditItemModal();
      })
      .catch(async (error) => {
        console.error('Error updating menu item:', error);
        // Try to parse error response JSON with errors array
        let serverErrors = null;
        try {
          if (error.message && error.message.includes('HTTP')) {
            const parts = error.message.split(':');
            const body = parts.slice(1).join(':').trim();
            serverErrors = JSON.parse(body);
          }
        } catch (_) {
          serverErrors = null;
        }

        const messages = [];
        if (serverErrors && Array.isArray(serverErrors.errors)) {
          serverErrors.errors.forEach((e) => messages.push(String(e)));
        }
        if (!messages.length)
          messages.push(
            error && error.message ? error.message : 'There was an error updating the menu item.'
          );

        // Render inline error in modal
        const body = this.hasEditItemFormTarget
          ? this.editItemFormTarget.closest('.modal-content')
          : null;
        if (body) {
          let alert = body.querySelector('.alert.alert-danger[data-role="item-save-errors"]');
          if (!alert) {
            alert = document.createElement('div');
            alert.className = 'alert alert-danger';
            alert.setAttribute('data-role', 'item-save-errors');
            const container = body.querySelector('.modal-body') || body;
            container.insertBefore(alert, container.firstChild);
          }
          alert.innerHTML = `<strong>Unable to save:</strong><ul>${messages.map((m) => `<li>${m}</li>`).join('')}</ul>`;
        } else {
          alert(messages.join('\n'));
        }
      })
      .finally(() => {
        if (btn) {
          btn.disabled = false;
          btn.innerHTML = origHtml || 'Save Changes';
        }
      });
  }

  // Helper method to capitalize first letter
  capitalize(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  // Toggle section items visibility
  toggleSection(event) {
    const sectionId = event.currentTarget.dataset.sectionId;
    const itemsContainer = document.querySelector(`[data-section-id="${sectionId}"]`);
    if (itemsContainer) {
      itemsContainer.classList.toggle('hidden');
    }
  }
}
