import { Controller } from '@hotwired/stimulus';
import Sortable from 'sortablejs';

/**
 * CRM Kanban Board Controller
 *
 * Drag-and-drop stage management using SortableJS (bundled, not CDN).
 * Enforces server-side transition rules on the client before calling the API.
 * Special cases:
 *   - Dropping onto "lost" opens a mini-modal to collect lost_reason.
 *   - Dropping onto "converted" is blocked — use the Convert button instead.
 *
 * Data attributes expected on the controller element:
 *   data-crm-kanban-transitions-value  — JSON of FORWARD_TRANSITIONS from server
 *   data-crm-kanban-lost-reasons-value — JSON array of LOST_REASONS from server
 *
 * Targets:
 *   cardList — each stage column's card list (data-stage="<stage>")
 *   modal    — the #leadModal Bootstrap modal element
 */
export default class extends Controller {
  static targets = ['cardList', 'modal'];
  static values = {
    transitions: Object,
    lostReasons: Array,
  };

  connect() {
    this._sortables = [];
    this._dragging = false;
    this._pendingDrop = null; // { card, oldList, oldIndex, newList, newStage }
    this._initAllColumns();
    this._bindLostModal();
  }

  disconnect() {
    this._sortables.forEach((s) => s.destroy());
    this._sortables = [];
  }

  // ─── Lead detail modal ────────────────────────────────────────────────────

  openLeadModal(event) {
    if (this._dragging) {
      event.preventDefault();
      return;
    }
    const modal = document.getElementById('leadModal');
    if (!modal) return;
    bootstrap.Modal.getOrCreateInstance(modal).show();
  }

  // ─── Sortable init ────────────────────────────────────────────────────────

  _initAllColumns() {
    if (!this.element.isConnected) return;

    this.cardListTargets.forEach((list) => {
      const columnStage = list.dataset.stage;

      const sortable = new Sortable(list, {
        group: 'crm-kanban',
        animation: 150,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        forceFallback: false,
        fallbackClass: 'sortable-fallback',

        // Block drops onto "converted" entirely
        onMove: (evt) => {
          const targetStage = evt.to.dataset.stage;
          if (targetStage === 'converted') return false;
          return true;
        },

        onStart: (evt) => {
          this._dragging = true;
          this._highlightValidTargets(evt.item);
        },

        onEnd: (evt) => {
          this._clearHighlights();
          setTimeout(() => { this._dragging = false; }, 100);
          this._onCardDropped(evt);
        },
      });

      this._sortables.push(sortable);
    });
  }

  // ─── Drop handler ─────────────────────────────────────────────────────────

  _onCardDropped(event) {
    const card = event.item;
    const newList = event.to;
    const oldList = event.from;
    const newStage = newList.dataset.stage;
    const oldStage = oldList.dataset.stage;

    // No-op: same column or no stage change
    if (newList === oldList || newStage === oldStage) return;

    // Validate transition against server rules
    const allowed = (this.transitionsValue[oldStage] || []);
    if (!allowed.includes(newStage)) {
      this._revertCard(card, oldList, event.oldIndex);
      this._showToast(`Cannot move from "${this._label(oldStage)}" to "${this._label(newStage)}"`, 'warning');
      return;
    }

    // "lost" needs extra info — intercept and show modal
    if (newStage === 'lost') {
      this._pendingDrop = {
        card,
        oldList,
        oldIndex: event.oldIndex,
        newStage,
        leadId: card.dataset.leadId,
      };
      this._openLostModal();
      return;
    }

    this._commitTransition({ card, oldList, oldIndex: event.oldIndex, newStage, leadId: card.dataset.leadId });
  }

  // ─── Transition API call ──────────────────────────────────────────────────

  async _commitTransition({ card, oldList, oldIndex, newStage, leadId, lostReason = null, lostReasonNotes = null }) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
    const url = `/admin/crm/leads/${leadId}/transition`;

    const body = { stage: newStage };
    if (lostReason) {
      body.lost_reason = lostReason;
      body.lost_reason_notes = lostReasonNotes;
    }

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          Accept: 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        this._revertCard(card, oldList, oldIndex);
        this._showToast(data.error || 'Stage update failed. Please try again.', 'danger');
        return;
      }

      this._showToast(`Moved to "${this._label(newStage)}"`, 'success');
    } catch (err) {
      console.error('[CrmKanban] Transition fetch error:', err);
      this._revertCard(card, oldList, oldIndex);
      this._showToast('Network error. Please try again.', 'danger');
    }
  }

  // ─── Lost reason modal ────────────────────────────────────────────────────

  _openLostModal() {
    const modal = document.getElementById('crmLostReasonModal');
    if (!modal) return;

    // Reset form
    const form = modal.querySelector('#crmLostReasonForm');
    if (form) form.reset();

    bootstrap.Modal.getOrCreateInstance(modal).show();
  }

  _bindLostModal() {
    const confirmBtn = document.getElementById('crmLostReasonConfirm');
    if (!confirmBtn) return;

    confirmBtn.addEventListener('click', () => {
      const modal = document.getElementById('crmLostReasonModal');
      const reasonSelect = modal?.querySelector('[name="lost_reason"]');
      const notesInput = modal?.querySelector('[name="lost_reason_notes"]');

      const lostReason = reasonSelect?.value;
      if (!lostReason) {
        reasonSelect?.classList.add('is-invalid');
        return;
      }
      reasonSelect?.classList.remove('is-invalid');

      bootstrap.Modal.getOrCreateInstance(modal).hide();

      if (this._pendingDrop) {
        this._commitTransition({
          ...this._pendingDrop,
          lostReason,
          lostReasonNotes: notesInput?.value || null,
        });
        this._pendingDrop = null;
      }
    });

    const modal = document.getElementById('crmLostReasonModal');
    modal?.addEventListener('hidden.bs.modal', () => {
      // If modal closed without confirming, revert the card
      if (this._pendingDrop) {
        const { card, oldList, oldIndex } = this._pendingDrop;
        this._revertCard(card, oldList, oldIndex);
        this._pendingDrop = null;
      }
    });
  }

  // ─── Visual feedback ──────────────────────────────────────────────────────

  _highlightValidTargets(draggedCard) {
    const sourceList = draggedCard.closest('[data-crm-kanban-target="cardList"]');
    const fromStage = sourceList?.dataset.stage;
    if (!fromStage) return;

    const allowed = new Set(this.transitionsValue[fromStage] || []);

    this.cardListTargets.forEach((list) => {
      const col = list.closest('.crm-kanban-column');
      if (!col) return;
      const stage = list.dataset.stage;
      if (stage === fromStage) return; // current column — neutral

      if (stage === 'converted') {
        col.classList.add('crm-kanban-column--blocked');
      } else if (allowed.has(stage)) {
        col.classList.add('crm-kanban-column--valid');
      } else {
        col.classList.add('crm-kanban-column--invalid');
      }
    });
  }

  _clearHighlights() {
    this.cardListTargets.forEach((list) => {
      const col = list.closest('.crm-kanban-column');
      col?.classList.remove('crm-kanban-column--valid', 'crm-kanban-column--invalid', 'crm-kanban-column--blocked');
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  _revertCard(card, originalList, originalIndex) {
    const ref = originalList.children[originalIndex] || null;
    originalList.insertBefore(card, ref);
  }

  _label(stage) {
    return stage.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
  }

  _showToast(message, type = 'danger') {
    const existing = document.getElementById('crm-kanban-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'crm-kanban-toast';
    toast.className = `alert alert-${type} position-fixed bottom-0 end-0 m-3 shadow`;
    toast.style.zIndex = '9999';
    toast.style.minWidth = '260px';
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => toast.remove(), 3500);
  }
}
