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
  static targets = ['cardList', 'modal', 'card'];
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
    this._bindModalFrameLoad();
  }

  disconnect() {
    this._sortables.forEach((s) => s.destroy());
    this._sortables = [];
  }

  // ─── Search / filter ─────────────────────────────────────────────────────

  search(event) {
    const query = event.target.value.trim().toLowerCase();

    this.cardTargets.forEach((card) => {
      const text = card.dataset.search || '';
      card.hidden = query.length > 0 && !text.includes(query);
    });

    // Update each column's count badge to reflect visible cards only
    this.cardListTargets.forEach((list) => {
      const visible = [...list.querySelectorAll('[data-crm-kanban-target="card"]')]
        .filter((c) => !c.hidden).length;
      const badge = list.closest('[data-stage]')?.querySelector('.badge.rounded-pill');
      if (badge) badge.textContent = visible;
    });
  }

  // ─── Lead detail modal ────────────────────────────────────────────────────

  openLeadModal(event) {
    // Only block navigation when a drag is in progress. The modal is shown
    // by _bindModalFrameLoad() once Turbo has finished loading the frame,
    // so we must NOT show it here (that would display stale content).
    if (this._dragging) {
      event.preventDefault();
    }
  }

  _bindModalFrameLoad() {
    const frame = document.getElementById('crm_lead_modal');
    if (!frame) return;
    frame.addEventListener('turbo:frame-load', () => {
      const modal = document.getElementById('leadModal');
      if (modal) bootstrap.Modal.getOrCreateInstance(modal).show();
    });
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

        // Block drops onto stages that are structurally or conditionally invalid
        onMove: (evt) => {
          const targetStage = evt.to.dataset.stage;
          return !this._isBlocked(evt.dragged, targetStage);
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

    // Check preconditions (assignee, etc.)
    const blockReason = this._preconditionError(card, newStage);
    if (blockReason) {
      this._revertCard(card, oldList, event.oldIndex);
      this._showToast(blockReason, 'warning');
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

  async _commitTransition({ card, oldList, oldIndex, newStage, leadId, lostReason = null, lostReasonNotes = null, fromModal = false }) {
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
        if (!fromModal) this._revertCard(card, oldList, oldIndex);
        this._showToast(data.error || 'Stage update failed. Please try again.', 'danger');
        return;
      }

      if (fromModal) {
        // Close the lead detail modal and refresh the board
        const leadModal = document.getElementById('leadModal');
        if (leadModal) bootstrap.Modal.getOrCreateInstance(leadModal).hide();
        Turbo.visit(window.location.href);
      } else {
        this._showToast(`Moved to "${this._label(newStage)}"`, 'success');
      }
    } catch (err) {
      console.error('[CrmKanban] Transition fetch error:', err);
      this._revertCard(card, oldList, oldIndex);
      this._showToast('Network error. Please try again.', 'danger');
    }
  }

  // ─── Lost from modal button (Move Stage panel) ───────────────────────────

  openLostModalForLead(event) {
    const leadId = event.currentTarget.dataset.leadId;
    this._pendingDrop = {
      card: document.getElementById(`crm-lead-card-${leadId}`),
      oldList: null,
      oldIndex: null,
      newStage: 'lost',
      leadId,
      fromModal: true,
    };
    this._openLostModal();
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
      // If modal closed without confirming, revert the card (drag-drop only)
      if (this._pendingDrop) {
        const { card, oldList, oldIndex, fromModal } = this._pendingDrop;
        if (!fromModal) this._revertCard(card, oldList, oldIndex);
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

      if (this._isBlocked(draggedCard, stage)) {
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

  // ─── Precondition helpers ─────────────────────────────────────────────────

  // Returns true if the card must not be dropped onto targetStage at all
  // (used by onMove to physically prevent the drop and by highlight logic).
  _isBlocked(card, targetStage) {
    if (targetStage === 'converted') return true;
    if (targetStage === 'demo_completed' && card.dataset.assigned !== 'true') return true;
    return false;
  }

  // Returns a human-readable error string when a drop should be rejected,
  // or null if the drop is allowed. Called after transition-map validation passes.
  _preconditionError(card, targetStage) {
    if (targetStage === 'demo_completed' && card.dataset.assigned !== 'true') {
      return 'Assign this lead to a team member before marking the demo as completed.';
    }
    return null;
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
