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
    'editItemImagePrompt',
    'editItemPrice',
    'editItemSection',
    'editItemAllergens',
    'editItemVegetarian',
    'editItemVegan',
    'editItemGlutenFree',
    'editItemDairyFree',
    'editItemNutFree',
    'pricingWrapper',
    'pricingModeBtn',
    'singlePriceSection',
    'sizePricesSection',
    'editSizePrice',
    'editItemSectionSize',
    'overallPercent',
    'overallSlider',
    'overallFill',
    'phaseText',
    'pageText',
    'phasePercent',
    'polishButton',
  ];

  static values = {
    progressUrl: String,
    polishUrl: String,
    polishProgressUrl: String,
    status: String,
  };

  connect() {
    console.debug('[menu-import] connect() — element:', this.element.className);
    // Initialize modals
    if (this.hasConfirmModalTarget) {
      this.confirmModal = Modal.getOrCreateInstance(this.confirmModalTarget);
      console.debug('[menu-import] confirmModal initialized');
    }

    if (this.hasEditItemModalTarget) {
      this.editItemModal = Modal.getOrCreateInstance(this.editItemModalTarget);
      console.debug('[menu-import] editItemModal initialized');
    } else {
      console.warn('[menu-import] editItemModalTarget NOT found at connect time');
    }

    // Add event listener for keyboard shortcuts
    document.addEventListener('keydown', this.handleKeyDown.bind(this));

    // Section-level pricing buttons
    this.element.addEventListener('click', this.handleSectionPriceClick.bind(this));

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

    const currentStatus = (this.hasStatusValue ? this.statusValue : '').toLowerCase();
    const shouldPoll = currentStatus === 'processing' || currentStatus === 'pending';
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
      } else if (phase === 'parsing_menu_vision') {
        this.phaseTextTarget.textContent = 'Analysing menu layout with vision…';
      } else if (phase === 'saving_menu') {
        this.phaseTextTarget.textContent = 'Saving menu items…';
      } else if (phase === 'estimating_prices') {
        this.phaseTextTarget.textContent = 'Estimating missing prices…';
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
    if (!this.hasEditItemModalTarget) {
      console.warn('[menu-import#showEditItemModal] editItemModalTarget not found — aborting');
      return;
    }

    // Lazy-init the Modal instance if connect() missed it
    if (!this.editItemModal) {
      console.debug('[menu-import#showEditItemModal] lazy-initializing Modal');
      this.editItemModal = Modal.getOrCreateInstance(this.editItemModalTarget);
    }

    const itemId = event.currentTarget.dataset.itemId;
    const itemName = event.currentTarget.dataset.itemName || '';
    const itemDescription = event.currentTarget.dataset.itemDescription || '';
    const itemImagePrompt = event.currentTarget.dataset.itemImagePrompt || '';
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
    if (this.hasEditItemImagePromptTarget) this.editItemImagePromptTarget.value = itemImagePrompt;
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

    // Populate size prices and set pricing mode
    let sizePrices = {};
    try {
      const raw = event.currentTarget.dataset.itemSizePrices || '{}';
      console.debug('[menu-import#showEditItemModal] raw itemSizePrices attr:', raw);
      sizePrices = JSON.parse(raw);
    } catch (e) {
      console.error('[menu-import#showEditItemModal] Error parsing size prices:', e);
      sizePrices = {};
    }
    console.debug('[menu-import#showEditItemModal] parsed sizePrices:', sizePrices);
    console.debug('[menu-import#showEditItemModal] hasEditSizePriceTarget:', this.hasEditSizePriceTarget);
    console.debug('[menu-import#showEditItemModal] editSizePriceTargets count:', this.hasEditSizePriceTarget ? this.editSizePriceTargets.length : 0);
    if (this.hasEditSizePriceTarget) {
      this.editSizePriceTargets.forEach(input => {
        const key = input.dataset.sizeKey;
        const val = sizePrices[key];
        console.debug(`[menu-import#showEditItemModal] size input key=${key} raw=${val} setting=${(val != null && parseFloat(val) > 0) ? val : ''}`);
        input.value = (val != null && parseFloat(val) > 0) ? val : '';
      });
    }

    // Sync the duplicate section selector in size mode
    if (this.hasEditItemSectionSizeTarget) {
      this.editItemSectionSizeTarget.value = itemSection;
    }

    // Auto-select pricing mode based on whether size prices exist
    const hasSizePrices = Object.values(sizePrices).some(v => v != null && parseFloat(v) > 0);
    console.debug('[menu-import#showEditItemModal] hasSizePrices:', hasSizePrices, '=> mode:', hasSizePrices ? 'sizes' : 'single');
    console.debug('[menu-import#showEditItemModal] hasPricingModeBtnTarget:', this.hasPricingModeBtnTarget);
    console.debug('[menu-import#showEditItemModal] hasSinglePriceSectionTarget:', this.hasSinglePriceSectionTarget);
    console.debug('[menu-import#showEditItemModal] hasSizePricesSectionTarget:', this.hasSizePricesSectionTarget);
    this._applyPricingMode(hasSizePrices ? 'sizes' : 'single');

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

  // Pricing mode toggle — called from btn-group click
  switchPricingMode(event) {
    const mode = event.currentTarget.dataset.pricingMode;
    if (mode) this._applyPricingMode(mode);
  }

  // Internal: show/hide the correct pricing panel and update button active state
  _applyPricingMode(mode) {
    // Toggle btn-group active states
    if (this.hasPricingModeBtnTarget) {
      this.pricingModeBtnTargets.forEach(btn => {
        btn.classList.toggle('active', btn.dataset.pricingMode === mode);
      });
    }

    // Show/hide panels
    if (this.hasSinglePriceSectionTarget) {
      this.singlePriceSectionTarget.style.display = mode === 'single' ? '' : 'none';
    }
    if (this.hasSizePricesSectionTarget) {
      this.sizePricesSectionTarget.style.display = mode === 'sizes' ? '' : 'none';
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

    // Collect size prices from inputs
    const sizePrices = {};
    if (this.hasEditSizePriceTarget) {
      this.editSizePriceTargets.forEach(input => {
        const key = input.dataset.sizeKey;
        const val = parseFloat(input.value);
        if (!isNaN(val) && val > 0) sizePrices[key] = val;
      });
    }

    // Detect the active pricing mode from the DOM (which panel is visible)
    const sizePanelVisible = this.hasSizePricesSectionTarget && this.sizePricesSectionTarget.style.display !== 'none';
    const pricingMode = sizePanelVisible ? 'sizes' : 'single';
    const singlePrice = pricingMode === 'single' ? (parseFloat(formData.get('item_price')) || 0) : 0;
    const finalSizePrices = pricingMode === 'sizes' ? sizePrices : {};

    const payload = {
      ocr_menu_item: {
        name: formData.get('item_name'),
        description: formData.get('item_description'),
        image_prompt: formData.get('item_image_prompt'),
        price: singlePrice,
        allergens: allergens,
        dietary_restrictions: dietaryRestrictions,
        size_prices: finalSizePrices,
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

            // Update price / size-prices display
            const spData = data.item?.size_prices || {};
            const spEntries = Object.entries(spData).filter(([, v]) => v != null && parseFloat(v) > 0);
            const priceArea = row.querySelector('.d-flex.align-items-center.gap-2.flex-shrink-0');

            if (priceArea) {
              // Remove old display elements
              const oldSizeDisp = priceArea.querySelector('[data-item-size-prices-display]');
              const oldPriceDisp = priceArea.querySelector('[data-item-price-display]');
              const oldEstBadge = priceArea.querySelector('.badge.bg-warning');
              if (oldSizeDisp) oldSizeDisp.remove();
              if (oldPriceDisp) oldPriceDisp.remove();
              if (oldEstBadge) oldEstBadge.remove();

              const editBtn = priceArea.querySelector('.btn');
              if (spEntries.length) {
                // Show size prices as primary display
                const sp = document.createElement('span');
                sp.className = 'text-muted small';
                sp.setAttribute('data-item-size-prices-display', id);
                sp.textContent = spEntries.map(([k, v]) => {
                  const label = k.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
                  return `${label}: ${parseFloat(v).toFixed(2)}`;
                }).join(' \u00b7 ');
                priceArea.insertBefore(sp, editBtn);
              } else {
                // Show single price
                const price = Number(item.price || 0);
                const sp = document.createElement('span');
                sp.className = 'fw-medium';
                sp.setAttribute('data-item-price-display', id);
                sp.textContent = price.toFixed(2);
                priceArea.insertBefore(sp, editBtn);
              }
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

            // Update edit trigger data attributes on the button for next open
            const editBtn = row.querySelector('[data-action="click->menu-import#showEditItemModal"]');
            if (editBtn) {
              editBtn.dataset.itemName = item.name || '';
              editBtn.dataset.itemDescription = item.description || '';
              editBtn.dataset.itemImagePrompt = item.image_prompt || '';
              editBtn.dataset.itemPrice = item.price || '';
              editBtn.dataset.itemAllergens = JSON.stringify(item.allergens || []);
              editBtn.dataset.itemSizePrices = JSON.stringify(item.size_prices || {});
              const diet = [];
              if (item.is_vegetarian) diet.push('vegetarian');
              if (item.is_vegan) diet.push('vegan');
              if (item.is_gluten_free) diet.push('gluten_free');
              if (item.is_dairy_free) diet.push('dairy_free');
              if (item.is_nut_free) diet.push('nut_free');
              editBtn.dataset.itemDietaryRestrictions = JSON.stringify(diet);
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

  // Section-level pricing: delegated click handler
  async handleSectionPriceClick(event) {
    const applyBtn = event.target.closest('[data-role="section-price-btn"]');
    const allBtn = event.target.closest('[data-role="section-price-all-btn"]');
    const btn = applyBtn || allBtn;
    if (!btn) return;

    const sectionId = btn.dataset.sectionId;
    const url = btn.dataset.url;
    const input = this.element.querySelector(`[data-role="section-price-input"][data-section-id="${sectionId}"]`);
    if (!input) return;

    const price = parseFloat(input.value);
    if (isNaN(price) || price < 0) {
      input.classList.add('is-invalid');
      return;
    }
    input.classList.remove('is-invalid');

    const overrideAll = !!allBtn;
    const origHtml = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span>';

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
      const res = await fetch(url, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({ section_id: sectionId, price: price, override_all: overrideAll }),
        credentials: 'same-origin',
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();

      if (data.ok) {
        // Reload to reflect updated prices and badges
        window.location.reload();
      } else {
        alert(data.error || 'Failed to update prices');
        btn.disabled = false;
        btn.innerHTML = origHtml;
      }
    } catch (e) {
      console.error('Section pricing error:', e);
      alert('Failed to update section prices');
      btn.disabled = false;
      btn.innerHTML = origHtml;
    }
  }

  async startPolish(event) {
    event.preventDefault();
    if (!this.hasPolishUrlValue || !this.hasPolishProgressUrlValue) return;
    if (!this.hasPolishButtonTarget) return;

    const btn = this.polishButtonTarget;
    const originalHtml = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span> Polishing…';

    let jobId = null;
    try {
      const res = await fetch(this.polishUrlValue, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content,
        },
        credentials: 'same-origin',
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      jobId = data.job_id;
    } catch (e) {
      btn.disabled = false;
      btn.innerHTML = originalHtml;
      return;
    }

    const poll = async () => {
      try {
        const u = new URL(this.polishProgressUrlValue, window.location.origin);
        u.searchParams.set('job_id', jobId);
        const res = await fetch(u.toString(), { headers: { Accept: 'application/json' }, credentials: 'same-origin' });
        if (!res.ok) return;
        const data = await res.json();
        const status = String(data.status || 'running');
        const msg = data.message || '';

        if (status === 'completed') {
          window.location.reload();
          return;
        }
        if (status === 'failed') {
          btn.disabled = false;
          btn.innerHTML = originalHtml;
          return;
        }

        if (msg) {
          btn.innerHTML = `<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span> ${msg}`;
        }
      } catch (_) {}
    };

    poll();
    window.setInterval(poll, 1500);
  }
}
