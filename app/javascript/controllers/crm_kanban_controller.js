import { Controller } from '@hotwired/stimulus';

/**
 * CRM Kanban Board Controller
 *
 * Initialises SortableJS on each stage column.
 * On drag-end, fires a PATCH to the transition endpoint with the new stage.
 * On success, moves the card to the new column.
 * On failure, reverts the card and shows a toast.
 *
 * Usage:
 *   <div data-controller="crm-kanban">
 *     <div data-crm-kanban-target="cardList" data-stage="new">...</div>
 *     <div data-crm-kanban-target="cardList" data-stage="contacted">...</div>
 *   </div>
 */

// Shared load promise so multiple columns don't race to load the CDN script.
let _sortableLoadPromise = null;

function ensureSortableLoaded() {
  if (window.Sortable) return Promise.resolve();

  if (!_sortableLoadPromise) {
    _sortableLoadPromise = new Promise((resolve, reject) => {
      const existing = document.querySelector('script[src*="sortablejs"]');
      if (existing) {
        const check = setInterval(() => {
          if (window.Sortable) {
            clearInterval(check);
            resolve();
          }
        }, 50);
        setTimeout(() => {
          clearInterval(check);
          resolve();
        }, 10000);
        return;
      }

      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js';
      script.onload = () => resolve();
      script.onerror = () => {
        _sortableLoadPromise = null;
        reject(new Error('SortableJS CDN load failed'));
      };
      document.head.appendChild(script);
    });
  }

  return _sortableLoadPromise;
}

export default class extends Controller {
  static targets = ['cardList'];

  connect() {
    this._sortables = [];
    this._initAllColumns();
  }

  disconnect() {
    this._sortables.forEach((s) => s.destroy());
    this._sortables = [];
  }

  async _initAllColumns() {
    try {
      await ensureSortableLoaded();
    } catch (e) {
      console.error('[CrmKanban] Failed to load SortableJS:', e);
      return;
    }

    if (!this.element.isConnected) return;

    this.cardListTargets.forEach((list) => {
      const sortable = new window.Sortable(list, {
        group: 'crm-kanban',
        animation: 150,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        forceFallback: true,
        fallbackClass: 'sortable-fallback',
        fallbackOnBody: true,
        onEnd: (event) => this._onCardDropped(event),
      });
      this._sortables.push(sortable);
    });
  }

  async _onCardDropped(event) {
    const card = event.item;
    const newList = event.to;
    const oldList = event.from;
    const newStage = newList.dataset.stage;
    const leadId = card.dataset.leadId;

    // No-op if dropped in same column
    if (newList === oldList && event.oldIndex === event.newIndex) return;
    // No-op if no stage change
    if (newList.dataset.stage === oldList.dataset.stage) return;

    const transitionUrl = `/admin/crm/leads/${leadId}/transition`;
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';

    try {
      const response = await fetch(transitionUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          Accept: 'application/json',
        },
        body: JSON.stringify({ stage: newStage }),
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        this._revertCard(card, oldList, event.oldIndex);
        this._showToast(data.error || 'Stage update failed. Please try again.', 'danger');
        return;
      }

      // Update stage badge on the card if present
      this._updateStageBadge(card, newStage);
    } catch (err) {
      console.error('[CrmKanban] Transition fetch error:', err);
      this._revertCard(card, oldList, event.oldIndex);
      this._showToast('Network error. Please try again.', 'danger');
    }
  }

  _revertCard(card, originalList, originalIndex) {
    const ref = originalList.children[originalIndex] || null;
    originalList.insertBefore(card, ref);
  }

  _updateStageBadge(_card, _newStage) {
    // Cards don't currently show stage — no DOM update needed.
    // Extend here if a stage indicator is added to the card partial.
  }

  _showToast(message, type = 'danger') {
    // Bootstrap toast or simple alert
    const existing = document.getElementById('crm-kanban-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'crm-kanban-toast';
    toast.className = `alert alert-${type} position-fixed bottom-0 end-0 m-3`;
    toast.style.zIndex = '9999';
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => toast.remove(), 4000);
  }
}
