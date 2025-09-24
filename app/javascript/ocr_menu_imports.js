// OCR Menu Imports module: initializes DnD where present and wires inline editors

export function initOCRMenuImportDnD() {
  const container = document.getElementById('sections-sortable');
  // Do not return early here; we still want inline editing (e.g., import title) to work

  // Set global flag so inline view JS can skip its own DnD init (harmless if repeated)
  try { window.OCR_DND_ACTIVE = true; } catch (_) {}

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
      /* Inline title edit affordances */
      .section-title-editable, .import-title-editable { cursor: text; position: relative; }
      .section-title-editable .edit-indicator, .import-title-editable .edit-indicator { opacity: 0; transition: opacity .15s; font-size: .9em; }
      .section-title-editable:hover .edit-indicator, .import-title-editable:hover .edit-indicator { opacity: .75; }
    `;
    document.head.appendChild(style);
  })();

  // Confirmation toggles (sections + master) — top-level, not per-section
  function initConfirmationToggles() {
    const csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';

    const sectionsContainer = document.getElementById('sections-sortable');
    if (!sectionsContainer) return;

    const master = document.querySelector('input[data-role="confirm-all-sections"]');
    const getSectionCheckboxes = () => Array.from(sectionsContainer.querySelectorAll('input.form-check-input[data-section-id]'));

    // Enable controls (disabled by default in HTML)
    if (master) master.disabled = false;
    getSectionCheckboxes().forEach(cb => { cb.disabled = false; });

    // Helper: compute master state from children
    const refreshMasterState = () => {
      if (!master) return;
      const cbs = getSectionCheckboxes();
      const total = cbs.length;
      const checked = cbs.filter(cb => cb.checked).length;
      master.indeterminate = checked > 0 && checked < total;
      master.checked = total > 0 && checked === total;
    };

    refreshMasterState();

    // Per-section change -> PATCH toggle_section_confirmation
    getSectionCheckboxes().forEach(cb => {
      cb.addEventListener('change', () => {
        const sectionId = cb.getAttribute('data-section-id');
        const url = cb.getAttribute('data-toggle-url');
        const confirmed = cb.checked;
        cb.disabled = true;
        fetch(url, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': csrf
          },
          body: JSON.stringify({ section_id: sectionId, confirmed })
        }).then(r => {
          if (!r.ok) throw new Error('HTTP ' + r.status);
          return r.json();
        }).then(() => {
          refreshMasterState();
        }).catch(() => {
          // Revert on error
          cb.checked = !confirmed;
        }).finally(() => {
          cb.disabled = false;
        });
      });
    });

    // Master change -> PATCH toggle_all_confirmation
    if (master) {
      master.addEventListener('change', () => {
        const url = master.getAttribute('data-toggle-all-url');
        const confirmed = master.checked;
        master.disabled = true;
        // Optimistically update all section checkboxes immediately
        const cbs = getSectionCheckboxes();
        cbs.forEach(cb => { cb.checked = confirmed; });
        refreshMasterState();
        fetch(url, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': csrf
          },
          body: JSON.stringify({ confirmed })
        }).then(r => {
          if (!r.ok) throw new Error('HTTP ' + r.status);
          return r.json();
        }).then(() => {
          refreshMasterState();
        }).catch(() => {
          // Revert on error
          master.checked = !confirmed;
          const cbs2 = getSectionCheckboxes();
          cbs2.forEach(cb => { cb.checked = !confirmed; });
          refreshMasterState();
        }).finally(() => {
          master.disabled = false;
        });
      });
    }
  }

  // Run once now and again on Turbo navigations
  try { initConfirmationToggles(); } catch(_) {}
  document.addEventListener('turbo:load', () => { try { initConfirmationToggles(); } catch(_) {} });
  document.addEventListener('DOMContentLoaded', () => { try { initConfirmationToggles(); } catch(_) {} });

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
    // If no explicit meta/url found, rely on inline per-section code
    if (!itemReorderUrl) {
      // no-op
    }

    document.querySelectorAll('[id^="section-"][id$="-items"]').forEach(el => {
      const sectionId = parseInt(el.id.replace('section-', '').replace('-items', ''));
      const itemContainer = el.querySelector('.vstack');
      if (!itemContainer) return;

      // Prevent click toggles on the handle after drag
      const handles = itemContainer.querySelectorAll('.item-drag-handle');
      handles.forEach((h) => {
        h.addEventListener('click', e => {
          try { e.preventDefault(); } catch (_) {}
        }, { passive: false });
      });

      function persistItems() {
        const itemIds = Array.from(itemContainer.querySelectorAll('.item-row'))
          .map(el => parseInt(el.getAttribute('data-item-id'), 10))
          .filter(n => !isNaN(n));
        const url = itemReorderUrl || (document.querySelector('meta[name="ocr-items-reorder-url"]') || {}).content;
        if (!url) { return; }
        persist(url, { section_id: sectionId, item_ids: itemIds }, `items(section:${sectionId})`);
      }

      if (typeof Sortable !== 'undefined') {
        try {
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
            onFilter: (evt) => {},
            onChoose: (evt) => {},
            onStart: (evt) => {},
            onMove: (evt) => {},
            onUnchoose: (evt) => {},
            onEnd: () => {
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

  // Kick off DnD initialization only when the sections container exists on the page
  if (container && !container.dataset.ocrDndAttached) {
    container.dataset.ocrDndAttached = 'true';
    ensureSortableThenInit();
  }

  // Inline edit for import title (H1)
  (function initInlineImportTitleEdit(){
    const titleEl = document.querySelector('.import-title-editable');
    if (!titleEl) return;
    if (titleEl.dataset.inlineBound === 'true') return; // idempotent binding
    titleEl.dataset.inlineBound = 'true';
    const updateUrl = titleEl.getAttribute('data-update-url');
    if (!updateUrl) return;

    // Ensure tooltip is active on the indicator if present
    try {
      const icon = titleEl.querySelector('.edit-indicator');
      if (icon && window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon);
    } catch (_) {}

    // Accessibility: make the title focusable/interactive
    try { titleEl.setAttribute('role', 'button'); titleEl.setAttribute('tabindex', '0'); } catch(_) {}

    const onClickTitle = (e) => {
      e.preventDefault();
      e.stopPropagation();

      // Operate on the element that was clicked (works after restore)
      const host = (e.currentTarget?.closest?.('.import-title-editable')) || e.currentTarget || titleEl;

      // Avoid multiple editors
      if (host.querySelector('input[data-role="import-title-input"]')) return;

      const originalText = (host.childNodes[0]?.textContent || host.textContent || '').replace(/\s*$/, '').trim();

      // Build editor
      const wrapper = document.createElement('div');
      wrapper.className = 'd-flex align-items-center gap-2 w-100';

      const input = document.createElement('input');
      input.type = 'text';
      input.className = 'form-control form-control-sm';
      input.value = originalText;
      input.setAttribute('data-role', 'import-title-input');
      input.style.maxWidth = '520px';

      const saveBtn = document.createElement('button');
      saveBtn.type = 'button';
      saveBtn.className = 'btn btn-sm btn-primary';
      saveBtn.innerHTML = '<i class="bi bi-save"></i>';

      const cancelBtn = document.createElement('button');
      cancelBtn.type = 'button';
      cancelBtn.className = 'btn btn-sm btn-outline-secondary';
      cancelBtn.innerHTML = '<i class="bi bi-x"></i>';

      // Replace title content with editor
      const parent = host.parentNode;
      const placeholder = document.createElement(host.tagName.toLowerCase());
      placeholder.className = host.className;
      parent.replaceChild(placeholder, host);
      placeholder.appendChild(wrapper);
      wrapper.appendChild(input);
      const btnGroup = document.createElement('div');
      btnGroup.className = 'btn-group btn-group-sm';
      btnGroup.setAttribute('role', 'group');
      btnGroup.appendChild(saveBtn);
      btnGroup.appendChild(cancelBtn);
      wrapper.appendChild(btnGroup);
      input.focus();

      const showInlineError = (msg) => {
        let errEl = wrapper.querySelector('[data-role="import-title-error"]');
        if (!errEl) {
          errEl = document.createElement('div');
          errEl.setAttribute('data-role', 'import-title-error');
          errEl.className = 'text-danger small';
          wrapper.appendChild(errEl);
        }
        errEl.textContent = msg;
      };

      const restore = (text) => {
        const newTitle = document.createElement(placeholder.tagName.toLowerCase());
        newTitle.className = placeholder.className;
        newTitle.textContent = text;
        const icon = document.createElement('span');
        icon.className = 'edit-indicator text-secondary ms-2';
        icon.innerHTML = '<i class="bi bi-pencil"></i>';
        newTitle.appendChild(icon);
        parent.replaceChild(newTitle, placeholder);
        // Re-bind handlers to allow re-edit without full refresh
        newTitle.addEventListener('click', onClickTitle);
        icon.addEventListener('click', onClickTitle);
        try { if (window.bootstrap?.Tooltip) new bootstrap.Tooltip(icon); } catch (_) {}
      };

      const persist = () => {
        const newName = input.value.trim();
        if (!newName) { showInlineError('Please enter a name.'); input.focus(); return; }
        if (newName === originalText) { restore(originalText); return; }
        saveBtn.disabled = true; cancelBtn.disabled = true; input.disabled = true;
        const csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';
        fetch(updateUrl, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': csrf },
          body: JSON.stringify({ ocr_menu_import: { name: newName } }),
          credentials: 'same-origin'
        }).then(resp => {
          if (!resp.ok) return resp.text().then(t => { throw new Error(t || `HTTP ${resp.status}`); });
          return resp.json().catch(() => ({}));
        }).then(() => {
          restore(newName);
        }).catch(err => {
          console.warn('[OCR InlineEdit][import-title] Failed to save title', err);
          showInlineError('Unable to save. Please try again.');
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

    // Bind click on the title and the pencil icon
    titleEl.addEventListener('click', onClickTitle);
    const pencil = titleEl.querySelector('.edit-indicator');
    if (pencil) pencil.addEventListener('click', onClickTitle);
    // Keyboard support
    titleEl.addEventListener('keydown', (ev) => {
      if (ev.key === 'Enter') { ev.preventDefault(); onClickTitle(ev); }
    });
  })();

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
