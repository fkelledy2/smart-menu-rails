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
  (function initSections() {
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
  })();

  // Items per section
  (function initItems() {
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
            // Allow grabbing either the grip or anywhere on the row
            handle: '.item-drag-handle, .item-row',
            draggable: '.item-row',
            animation: 150,
            ghostClass: 'dragging',
            forceFallback: true,
            fallbackOnBody: true,
            fallbackTolerance: 0,
            touchStartThreshold: 0,
            dragoverBubble: true,
            // Do not start drag from interactive elements
            filter: 'a, button, .btn, input, select, textarea, [data-bs-toggle]',
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
  })();
}
