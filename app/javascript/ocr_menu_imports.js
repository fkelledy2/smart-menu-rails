// OCR Menu Imports DnD module
// This module initializes section and item drag-and-drop and logs to console for debugging.

let ocrDnDInitialized = false;

export function initOCRMenuImportDnD() {
  const container = document.getElementById('sections-sortable');
  if (!container) {
    // Not on OCR imports page
    return;
  }

  if (ocrDnDInitialized) {
    console.log('[OCR DnD] Already initialized, skipping');
    return;
  }

  ocrDnDInitialized = true;
  // Set global flag so inline view JS can skip its own DnD init
  try { window.OCR_DND_ACTIVE = true; } catch (_) {}
  console.log('[OCR DnD] Initializing drag-and-drop');

  // Inject minimal styles previously defined inline in the view
  (function injectStyles(){
    const id = 'ocr-menu-imports-dnd-styles';
    if (document.getElementById(id)) return;
    const style = document.createElement('style');
    style.id = id;
    style.textContent = `
      .section-drag-handle, .item-drag-handle { cursor: grab; opacity: 0.6; transition: opacity 0.2s; user-select: none; touch-action: none; }
      .section-drag-handle:hover, .item-drag-handle:hover { opacity: 1; }
      .section-container.dragging, .item-row.dragging { opacity: 0.5; background: #f8f9fa; border-radius: 4px; }
      /* Inline section title edit affordance */
      .section-title-editable { cursor: text; position: relative; }
      .section-title-editable .edit-indicator { opacity: 0; transition: opacity .15s; font-size: .9em; }
      .section-title-editable:hover .edit-indicator { opacity: .75; }
    `;
    document.head.appendChild(style);
  })();

  // Inline edit for section descriptions
  (function initInlineSectionDescriptionEdit(){
    const sections = document.querySelectorAll('.section-container');
    sections.forEach(section => {
      const sectionId = section.getAttribute('data-menu-section-section-id');
      if (!sectionId) return;
      // Expect a section description element with these classes (unique vs item descriptions)
      const descEl = section.querySelector('.py-2.px-3.text-muted');
      if (!descEl) return;

      // Add hover edit indicator once
      if (!descEl.querySelector('.edit-indicator')) {
        const icon = document.createElement('span');
        icon.className = 'edit-indicator text-secondary ms-2';
        icon.innerHTML = '<i class="bi bi-pencil"></i>';
        icon.setAttribute('title', 'Click to edit');
        icon.setAttribute('data-bs-toggle', 'tooltip');
        icon.setAttribute('data-bs-placement', 'top');
        descEl.classList.add('section-title-editable');
        descEl.appendChild(icon);
        try { if (window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon); } catch (_) {}
      }

      const onClickDesc = (e) => {
        e.preventDefault();
        e.stopPropagation();

        // If already editing, ignore
        if (section.querySelector('textarea[data-role="section-desc-input"]')) return;

        const currentDesc = e.currentTarget;
        const originalText = (currentDesc.textContent || '').trim();

        const wrapper = document.createElement('div');
        wrapper.className = 'd-flex align-items-start px-2 py-2 gap-2 w-100';

        const textarea = document.createElement('textarea');
        textarea.className = 'form-control form-control-sm';
        textarea.rows = 1;
        textarea.value = originalText;
        if (!originalText) textarea.placeholder = 'Add a section description';
        textarea.setAttribute('data-role', 'section-desc-input');
        textarea.style.maxWidth = '560px';

        const saveBtn = document.createElement('button');
        saveBtn.type = 'button';
        saveBtn.className = 'btn btn-sm btn-primary';
        saveBtn.innerHTML = '<i class="bi bi-save"></i>';
        const cancelBtn = document.createElement('button');
        cancelBtn.type = 'button';
        cancelBtn.className = 'btn btn-sm btn-outline-secondary';
        cancelBtn.innerHTML = '<i class="bi bi-x"></i>';

        // Replace with editor
        currentDesc.parentNode.replaceChild(wrapper, currentDesc);
        wrapper.appendChild(textarea);
        // Create a single button group for actions
        const btnGroupDesc = document.createElement('div');
        btnGroupDesc.className = 'btn-group btn-group-sm';
        btnGroupDesc.setAttribute('role', 'group');
        btnGroupDesc.appendChild(saveBtn);
        btnGroupDesc.appendChild(cancelBtn);
        wrapper.appendChild(btnGroupDesc);
        textarea.focus();

        const restore = (text) => {
          const newDesc = document.createElement('div');
          newDesc.className = 'py-2 px-3 text-muted section-title-editable';
          newDesc.textContent = text;
          const icon = document.createElement('span');
          icon.className = 'edit-indicator text-secondary ms-2';
          icon.innerHTML = '<i class="bi bi-pencil"></i>';
          newDesc.appendChild(icon);
          wrapper.parentNode.replaceChild(newDesc, wrapper);
          newDesc.addEventListener('click', onClickDesc);
          try { if (window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon); } catch (_) {}
        };

        const showInlineError = (msg) => {
          let errEl = section.querySelector('[data-role="section-desc-error"]');
          if (!errEl) {
            errEl = document.createElement('div');
            errEl.setAttribute('data-role', 'section-desc-error');
            errEl.className = 'text-danger small mt-1';
            wrapper.appendChild(errEl);
          }
          errEl.textContent = msg;
        };

        let saving = false;
        const persist = () => {
          if (saving) return;
          saving = true;
          const newVal = textarea.value.trim();
          if (newVal === originalText) { restore(originalText); return; }
          saveBtn.disabled = true; cancelBtn.disabled = true; textarea.disabled = true;
          const payload = { ocr_menu_section: { description: newVal } };
          const csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
          fetch(`/ocr_menu_sections/${sectionId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': csrf },
            body: JSON.stringify(payload),
            credentials: 'same-origin'
          }).then(resp => {
            if (!resp.ok) return resp.text().then(t => { throw new Error(t || `HTTP ${resp.status}`); });
            return resp.json().catch(() => ({}));
          }).then(() => {
            restore(newVal);
          }).catch(err => {
            console.warn('[OCR InlineEdit][section-desc] Failed to save description', err);
            showInlineError('Unable to save. Please try again.');
            saveBtn.disabled = false; cancelBtn.disabled = false; textarea.disabled = false;
            saving = false;
            textarea.focus();
          });
        };

        saveBtn.addEventListener('click', (ev) => { ev.stopPropagation(); persist(); });
        cancelBtn.addEventListener('click', (ev) => { ev.stopPropagation(); restore(originalText); });
        textarea.addEventListener('keydown', (ev) => {
          if (ev.key === 'Enter' && (ev.metaKey || ev.ctrlKey)) { ev.preventDefault(); persist(); }
          if (ev.key === 'Escape') { ev.preventDefault(); restore(originalText); }
        });
        // Save on blur for description
        textarea.addEventListener('blur', () => {
          // If cancel/save just clicked, wrapper might be removed; guard by presence
          if (!document.body.contains(textarea)) return;
          persist();
        });
      };

      descEl.addEventListener('click', onClickDesc);
    });
  })();

  // Initialize TomSelect for allergens (was previously inline)
  function initAllergensTomSelect(){
    const el = document.getElementById('item_allergens');
    if (!el) return;
    if (el.tomselect) {
      try { el.tomselect.destroy(); } catch(_) {}
    }
    if (typeof TomSelect === 'undefined') return;
    new TomSelect(el, {
      plugins: ['remove_button'],
      maxItems: null,
      create: false,
      closeAfterSelect: false,
      placeholder: 'Select allergens',
      render: {
        option: function(data, escape) { return '<div>' + escape(data.text) + '</div>'; },
        item: function(data, escape) { return '<div>' + escape(data.text) + '</div>'; }
      }
    });
  }

  // Wire up Edit Item modal population (was previously inline)
  function initEditItemModal(){
    const editItemModal = document.getElementById('editItemModal');
    if (!editItemModal) return;
    editItemModal.addEventListener('show.bs.modal', function(event){
      const trigger = event.relatedTarget;
      if (!trigger) return;
      const idInput = document.querySelector('[data-menu-import-target="editItemId"]');
      const nameInput = document.getElementById('item_name');
      const descInput = document.getElementById('item_description');
      const priceInput = document.getElementById('item_price');
      const sectionSelect = document.getElementById('item_section');
      const positionInput = document.getElementById('item_position');
      if (idInput) idInput.value = trigger.getAttribute('data-item-id') || '';
      if (nameInput) nameInput.value = trigger.getAttribute('data-item-name') || '';
      if (descInput) descInput.value = trigger.getAttribute('data-item-description') || '';
      if (priceInput) priceInput.value = trigger.getAttribute('data-item-price') || '';
      if (sectionSelect) {
        sectionSelect.value = trigger.getAttribute('data-item-section') || '';
        sectionSelect.setAttribute('disabled', 'disabled');
        sectionSelect.title = 'Section cannot be changed here.';
      }
      if (positionInput) positionInput.value = trigger.getAttribute('data-item-position') || '';
      // Allergens populate
      let allergensData = [];
      try { allergensData = JSON.parse(trigger.getAttribute('data-item-allergens') || '[]'); } catch(_) { allergensData = []; }
      const allergensSelect = document.getElementById('item_allergens');
      if (allergensSelect) {
        if (allergensSelect.tomselect) {
          try { allergensSelect.tomselect.setValue(allergensData, true); } catch(_) {}
        } else if (window.$) {
          try { window.$(allergensSelect).val(allergensData).trigger('change'); } catch(_) {}
        } else {
          Array.from(allergensSelect.options).forEach(function(opt){ opt.selected = allergensData.includes(opt.value); });
        }
      }
      // Dietary checkboxes
      let diet = [];
      try { diet = JSON.parse(trigger.getAttribute('data-item-dietary-restrictions') || '[]'); } catch(_) { diet = []; }
      function setChecked(id, key){ const el = document.getElementById(id); if (el) el.checked = diet.includes(key); }
      setChecked('item_vegetarian', 'vegetarian');
      setChecked('item_vegan', 'vegan');
      setChecked('item_gluten_free', 'gluten_free');
      setChecked('item_dairy_free', 'dairy_free');
    });
  }

  // Initialize helpers
  initAllergensTomSelect();
  document.addEventListener('turbo:before-stream-render', initAllergensTomSelect);
  initEditItemModal();

  // Helpers
  function persist(url, payload, label) {
    console.log(`[OCR DnD] Persist ${label}`, payload);
    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': (document.querySelector("meta[name='csrf-token']") || {}).content || ''
      },
      body: JSON.stringify(payload)
    })
      .then(r => r.text().then(t => { console.log(`[OCR DnD] Persist ${label} status`, r.status, t); }))
      .catch(e => console.warn(`[OCR DnD] Persist ${label} failed`, e));
  }

  // Sections via SortableJS if available; fallback to HTML5 DnD
  function initSections() {
    const reorderUrl = container.getAttribute('data-reorder-url');
    if (!reorderUrl) {
      console.warn('[OCR DnD][sections] Missing data-reorder-url');
      return;
    }

    function currentSectionIds() {
      return Array.from(container.querySelectorAll('.section-container')).map(el => parseInt(el.getAttribute('data-menu-section-section-id'), 10));
    }

    function initFallback() {
      console.log('[OCR DnD][sections] Using HTML5 DnD fallback');
      container.querySelectorAll('.section-container').forEach(item => {
        if (!item.hasAttribute('draggable')) item.setAttribute('draggable', 'true');
        const handle = item.querySelector('.section-drag-handle');
        if (handle) {
          handle.addEventListener('mousedown', ev => ev.stopPropagation());
          handle.addEventListener('click', ev => { ev.stopPropagation(); ev.preventDefault(); });
        }
        item.addEventListener('dragstart', e => {
          if (!e.target.closest('.section-drag-handle')) { e.preventDefault(); return; }
          e.dataTransfer.effectAllowed = 'move';
          item.classList.add('dragging');
          console.log('[OCR DnD][sections] dragstart', item.dataset.menuSectionSectionId);
        });
        item.addEventListener('dragend', () => {
          item.classList.remove('dragging');
          const ids = currentSectionIds();
          persist(reorderUrl, { section_ids: ids }, 'sections');
        });
      });
      container.addEventListener('dragover', e => {
        e.preventDefault();
        const dragging = container.querySelector('.section-container.dragging');
        if (!dragging) return;
        const els = Array.from(container.querySelectorAll('.section-container:not(.dragging)'));
        let closest = { offset: Number.NEGATIVE_INFINITY, el: null };
        els.forEach(child => {
          const box = child.getBoundingClientRect();
          const offset = e.clientY - box.top - box.height / 2;
          if (offset < 0 && offset > closest.offset) closest = { offset, el: child };
        });
        if (closest.el) container.insertBefore(dragging, closest.el); else container.appendChild(dragging);
      });
    }

    if (typeof Sortable !== 'undefined') {
      try {
        console.log('[OCR DnD][sections] Initializing SortableJS');
        // Remove native draggable attribute; let Sortable control it
        container.querySelectorAll('.section-container').forEach(el => el.removeAttribute('draggable'));
        new Sortable(container, {
          handle: '.section-drag-handle',
          animation: 150,
          ghostClass: 'dragging',
          forceFallback: true, // avoid native HTML5 drag interfering with collapse header
          fallbackOnBody: true,
          onChoose: (evt) => {
            console.log('[OCR DnD][sections] onChoose index=', evt.oldIndex, 'id=', evt.item?.dataset?.menuSectionSectionId);
          },
          onStart: (evt) => {
            console.log('[OCR DnD][sections] onStart index=', evt.oldIndex, 'id=', evt.item?.dataset?.menuSectionSectionId);
          },
          onMove: (evt) => {
            // Lightweight trace
            // console.debug('[OCR DnD][sections] onMove to index=', evt.newIndex);
          },
          onEnd: () => {
            const ids = currentSectionIds();
            persist(reorderUrl, { section_ids: ids }, 'sections');
          }
        });
        return;
      } catch (e) {
        console.warn('[OCR DnD][sections] Sortable init failed, fallback', e);
      }
    }
    // Fallback
    initFallback();
  }

  // Items per section
  function initItems() {
    const itemReorderUrl = container.getAttribute('data-reorder-items-url') ||
      (function(){
        // We will infer from the DOM by picking any section id; but better to use a fixed URL in the view
        const urlMeta = document.querySelector('meta[name="ocr-items-reorder-url"]');
        return urlMeta ? urlMeta.content : null;
      })();
    // If no explicit meta/url found, we will fall back to the inline fetch in the view code for items; skip here
    if (!itemReorderUrl) {
      console.log('[OCR DnD][items] No global reorder URL meta found; relying on inline per-section code');
    }

    document.querySelectorAll('[id^="section-"][id$="-items"]').forEach(el => {
      const sectionId = parseInt(el.id.replace('section-', '').replace('-items', ''));
      const itemContainer = el.querySelector('.vstack');
      if (!itemContainer) return;

      // Diagnostics: count handles per section
      const handles = itemContainer.querySelectorAll('.item-drag-handle');
      console.log('[OCR DnD][items] Section', sectionId, 'handle count=', handles.length);
      handles.forEach((h, idx) => {
        // Let Sortable receive events: do NOT stop propagation here
        ['pointerdown','mousedown','touchstart'].forEach(evt => {
          h.addEventListener(evt, e => {
            console.log(`[OCR DnD][items] handle ${evt} section=${sectionId} idx=${idx}`);
          }, { passive: true });
        });
        // Prevent click toggles on the handle after drag
        h.addEventListener('click', e => {
          console.log(`[OCR DnD][items] handle click section=${sectionId} idx=${idx}`);
          try { e.preventDefault(); } catch (_) {}
        }, { passive: false });
      });

      function persistItems() {
        const itemIds = Array.from(itemContainer.querySelectorAll('.item-row'))
          .map(el => parseInt(el.getAttribute('data-item-id'), 10))
          .filter(n => !isNaN(n));
        const url = itemReorderUrl || (document.querySelector('meta[name="ocr-items-reorder-url"]') || {}).content;
        if (!url) {
          console.log('[OCR DnD][items] Persist via inline view handler will handle this');
          return;
        }
        persist(url, { section_id: sectionId, item_ids: itemIds }, `items(section:${sectionId})`);
      }

      if (typeof Sortable !== 'undefined') {
        try {
          console.log('[OCR DnD][items] Initializing SortableJS for section', sectionId);
          // Remove native draggable attributes set by any fallback/inline code
          itemContainer.querySelectorAll('.item-row').forEach(r => r.removeAttribute('draggable'));
          new Sortable(itemContainer, {
            // Only allow dragging when grabbing the explicit handle
            handle: '.item-drag-handle',
            draggable: '.item-row',
            animation: 150,
            ghostClass: 'dragging',
            forceFallback: true,
            fallbackOnBody: true,
            fallbackTolerance: 0,
            touchStartThreshold: 0,
            dragoverBubble: true,
            // Do not start drag from interactive elements
            filter: 'input, select, textarea',
            preventOnFilter: true,
            setData: (dataTransfer, dragEl) => {
              try { dataTransfer.setData('text', dragEl.dataset.itemId || ''); } catch (_) {}
            },
            onFilter: (evt) => {
              console.log('[OCR DnD][items] onFilter prevented drag from interactive element', evt.target);
            },
            onChoose: (evt) => {
              console.log('[OCR DnD][items] onChoose index=', evt.oldIndex, 'itemId=', evt.item?.dataset?.itemId, 'section=', sectionId);
            },
            onStart: (evt) => {
              console.log('[OCR DnD][items] onStart index=', evt.oldIndex, 'itemId=', evt.item?.dataset?.itemId, 'section=', sectionId);
            },
            onMove: (evt) => {
              // console.debug('[OCR DnD][items] onMove newIndex=', evt.newIndex, 'section=', sectionId);
            },
            onUnchoose: (evt) => {
              console.log('[OCR DnD][items] onUnchoose index=', evt.oldIndex, 'itemId=', evt.item?.dataset?.itemId, 'section=', sectionId);
            },
            onEnd: () => {
              console.log('[OCR DnD][items] onEnd persist section', sectionId);
              persistItems();
            }
          });
          return;
        } catch (e) {
          console.warn('[OCR DnD][items] Sortable init failed, fallback', e);
        }
      }

      // Fallback
      itemContainer.querySelectorAll('.item-row').forEach(row => {
        row.setAttribute('draggable', 'true');
        const handle = row.querySelector('.item-drag-handle');
        if (handle) handle.addEventListener('mousedown', e => e.stopPropagation());
        row.addEventListener('dragstart', e => {
          if (!e.target.closest('.item-drag-handle')) { e.preventDefault(); return; }
          e.dataTransfer.effectAllowed = 'move';
          row.classList.add('dragging');
          console.log('[OCR DnD][items] dragstart', row.dataset.itemId);
        });
        row.addEventListener('dragend', () => {
          row.classList.remove('dragging');
          persistItems();
        });
      });
      itemContainer.addEventListener('dragover', e => {
        e.preventDefault();
        const dragging = itemContainer.querySelector('.item-row.dragging');
        if (!dragging) return;
        const els = Array.from(itemContainer.querySelectorAll('.item-row:not(.dragging)'));
        let closest = { offset: Number.NEGATIVE_INFINITY, el: null };
        els.forEach(child => {
          const box = child.getBoundingClientRect();
          const offset = e.clientY - box.top - box.height / 2;
          if (offset < 0 && offset > closest.offset) closest = { offset, el: child };
        });
        if (closest.el) itemContainer.insertBefore(dragging, closest.el); else itemContainer.appendChild(dragging);
      });
    });
  }

  // Ensure Sortable is loaded, then initialize DnD
  function ensureSortableThenInit() {
    if (typeof Sortable !== 'undefined') {
      initSections();
      initItems();
      return;
    }
    const existing = document.querySelector('script[data-ocr-sortable]');
    if (existing) {
      existing.addEventListener('load', () => { initSections(); initItems(); }, { once: true });
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js';
    script.async = true;
    script.defer = true;
    script.setAttribute('data-ocr-sortable', 'true');
    script.onload = function() { initSections(); initItems(); };
    document.head.appendChild(script);
  }

  // Kick off initialization ordering
  ensureSortableThenInit();

  // Inline edit for section titles
  (function initInlineSectionTitleEdit(){
    const sections = document.querySelectorAll('.section-container');
    sections.forEach(section => {
      const sectionId = section.getAttribute('data-menu-section-section-id');
      const headerGrow = section.querySelector('.card-header .flex-grow-1');
      const titleEl = headerGrow ? headerGrow.querySelector('h3.h5') : null;
      if (!sectionId || !titleEl) return;

      // Bind click handler (we'll reattach after editing too)

      // Add edit indicator
      if (!titleEl.querySelector('.edit-indicator')) {
        const icon = document.createElement('span');
        icon.className = 'edit-indicator text-secondary ms-2';
        icon.innerHTML = '<i class="bi bi-pencil"></i>';
        titleEl.classList.add('section-title-editable');
        titleEl.appendChild(icon);
        try { if (window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon); } catch (_) {}
      }

      const onClickTitle = (e) => {
        e.preventDefault();
        e.stopPropagation(); // don't toggle collapse

        // If already editing, ignore
        if (headerGrow.querySelector('input[data-role="section-title-input"]')) return;

        const currentTitle = e.currentTarget;
        const originalText = (currentTitle.textContent || '').replace(/\s*$/, '').trim();

        // Build editor
        const wrapper = document.createElement('div');
        wrapper.className = 'd-flex align-items-center gap-2 w-100';

        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'form-control form-control-sm';
        input.value = originalText;
        input.setAttribute('data-role', 'section-title-input');
        input.style.maxWidth = '420px';

        const saveBtn = document.createElement('button');
        saveBtn.type = 'button';
        saveBtn.className = 'btn btn-sm btn-primary';
        saveBtn.innerHTML = '<i class="bi bi-save"></i>';

        const cancelBtn = document.createElement('button');
        cancelBtn.type = 'button';
        cancelBtn.className = 'btn btn-sm btn-outline-secondary';
        cancelBtn.innerHTML = '<i class="bi bi-x"></i>';

        // Replace the clicked title with editor
        headerGrow.replaceChild(wrapper, currentTitle);
        wrapper.appendChild(input);
        // Create a single button group for actions
        const btnGroupTitle = document.createElement('div');
        btnGroupTitle.className = 'btn-group btn-group-sm';
        btnGroupTitle.setAttribute('role', 'group');
        btnGroupTitle.appendChild(saveBtn);
        btnGroupTitle.appendChild(cancelBtn);
        wrapper.appendChild(btnGroupTitle);
        input.focus();

        // Also open description editor for this section (even if blank)
        try {
          const descEl = section.querySelector('.py-2.px-3.text-muted');
          const alreadyEditing = section.querySelector('textarea[data-role="section-desc-input"]');
          if (descEl && !alreadyEditing) {
            // If description text is blank, ensure the upcoming textarea shows placeholder
            if (!descEl.textContent || !descEl.textContent.trim()) {
              // dispatch click; handler will set placeholder
              descEl.dispatchEvent(new Event('click', { bubbles: true }));
            } else {
              descEl.dispatchEvent(new Event('click', { bubbles: true }));
            }
          }
        } catch (_) {}

        const restore = (text) => {
          const newTitle = document.createElement('h3');
          newTitle.className = 'h5 mb-0 section-title-editable';
          newTitle.textContent = text;
          // attach edit indicator
          const icon = document.createElement('span');
          icon.className = 'edit-indicator text-secondary ms-2';
          icon.innerHTML = '<i class="bi bi-pencil"></i>';
          icon.setAttribute('title', 'Click to edit');
          icon.setAttribute('data-bs-toggle', 'tooltip');
          icon.setAttribute('data-bs-placement', 'top');
          newTitle.appendChild(icon);
          // replace editor with new title and rebind click handler
          headerGrow.replaceChild(newTitle, wrapper);
          newTitle.addEventListener('click', onClickTitle);
          try { if (window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon); } catch (_) {}
        };

        const showInlineError = (msg) => {
          let errEl = headerGrow.querySelector('[data-role="section-title-error"]');
          if (!errEl) {
            errEl = document.createElement('div');
            errEl.setAttribute('data-role', 'section-title-error');
            errEl.className = 'text-danger small';
            wrapper.appendChild(errEl);
          }
          errEl.textContent = msg;
        };

        const persist = () => {
          const newName = input.value.trim();
          if (!newName) { showInlineError('Please enter a name.'); input.focus(); return; }
          if (newName === originalText) { restore(originalText); return; }
          saveBtn.disabled = true; cancelBtn.disabled = true; input.disabled = true;
          const payload = { ocr_menu_section: { name: newName } };
          const csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
          fetch(`/ocr_menu_sections/${sectionId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': csrf },
            body: JSON.stringify(payload),
            credentials: 'same-origin'
          }).then(resp => {
            if (!resp.ok) return resp.text().then(t => { throw new Error(t || `HTTP ${resp.status}`); });
            return resp.json().catch(() => ({}));
          }).then(() => {
            restore(newName);
          }).catch(err => {
            console.warn('[OCR InlineEdit][section] Failed to save title', err);
            // Show a small inline error and re-enable inputs
            let errEl = headerGrow.querySelector('[data-role="section-title-error"]');
            if (!errEl) {
              errEl = document.createElement('div');
              errEl.setAttribute('data-role', 'section-title-error');
              errEl.className = 'text-danger small';
              wrapper.appendChild(errEl);
            }
            errEl.textContent = 'Unable to save. Please try again.';
            saveBtn.disabled = false; cancelBtn.disabled = false; input.disabled = false;
            input.focus();
          });
        };

        saveBtn.addEventListener('click', (ev) => { ev.stopPropagation(); persist(); });
        cancelBtn.addEventListener('click', (ev) => { ev.stopPropagation(); restore(originalText); });
        input.addEventListener('keydown', (ev) => {
          if (ev.key === 'Enter') { ev.preventDefault(); persist(); }
          if (ev.key === 'Escape') { ev.preventDefault(); restore(originalText); }
        });
      };

      titleEl.addEventListener('click', onClickTitle);
    });
  })();
}
