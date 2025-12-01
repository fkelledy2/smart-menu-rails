import { Controller } from "@hotwired/stimulus";

// StateController: single source of truth in the browser
// - Reads state from #contextContainer.dataset
// - Dispatches state:* events for view controllers
// - Owns simple UI reconciliations (e.g., header CTA visibility)
export default class extends Controller {
  static values = {
    // optional future bootstrap state via data-state-value (JSON)
    state: Object
  }

  // Apply JSON state payload (replace or shallow-merge critical fields)
  applyJsonState(payload) {
    const prev = this.state || {};
    const hasOrderKey = Object.prototype.hasOwnProperty.call(payload, 'order');
    const next = {
      session: payload.session ?? prev.session ?? null,
      order: hasOrderKey ? {
        id: payload.order?.id ?? null,
        status: payload.order?.status ?? null,
        items: Array.isArray(payload.order?.items) ? payload.order.items : [],
        addedCount: typeof payload.order?.addedCount !== 'undefined' ? payload.order.addedCount : 0,
        orderedCount: typeof payload.order?.orderedCount !== 'undefined' ? payload.order.orderedCount : 0,
        totalCount: typeof payload.order?.totalCount !== 'undefined' ? payload.order.totalCount : 0,
        openedCount: typeof payload.order?.openedCount !== 'undefined' ? payload.order.openedCount : 0,
        removedCount: typeof payload.order?.removedCount !== 'undefined' ? payload.order.removedCount : 0,
        orderedOnlyCount: typeof payload.order?.orderedOnlyCount !== 'undefined' ? payload.order.orderedOnlyCount : 0,
        preparingCount: typeof payload.order?.preparingCount !== 'undefined' ? payload.order.preparingCount : 0,
        readyCount: typeof payload.order?.readyCount !== 'undefined' ? payload.order.readyCount : 0,
        deliveredCount: typeof payload.order?.deliveredCount !== 'undefined' ? payload.order.deliveredCount : 0,
        billrequestedCount: typeof payload.order?.billrequestedCount !== 'undefined' ? payload.order.billrequestedCount : 0,
        paidCount: typeof payload.order?.paidCount !== 'undefined' ? payload.order.paidCount : 0,
        closedCount: typeof payload.order?.closedCount !== 'undefined' ? payload.order.closedCount : 0
      } : {
        // If no 'order' key in payload, preserve previous (old event type)
        id: prev.order?.id ?? null,
        status: prev.order?.status ?? null,
        items: Array.isArray(prev.order?.items) ? prev.order.items : [],
        addedCount: prev.order?.addedCount || 0,
        orderedCount: prev.order?.orderedCount || 0,
        totalCount: prev.order?.totalCount || 0,
        openedCount: prev.order?.openedCount || 0,
        removedCount: prev.order?.removedCount || 0,
        orderedOnlyCount: prev.order?.orderedOnlyCount || 0,
        preparingCount: prev.order?.preparingCount || 0,
        readyCount: prev.order?.readyCount || 0,
        deliveredCount: prev.order?.deliveredCount || 0,
        billrequestedCount: prev.order?.billrequestedCount || 0,
        paidCount: prev.order?.paidCount || 0,
        closedCount: prev.order?.closedCount || 0
      },
      totals: payload.totals ?? prev.totals ?? null,
      flags: payload.flags ?? prev.flags ?? {},
      tableId: payload.tableId ?? prev.tableId ?? null,
      employeeId: payload.employeeId ?? prev.employeeId ?? null,
      menuId: payload.menuId ?? prev.menuId ?? null,
      restaurant: {
        id: payload.restaurant?.id ?? prev.restaurant?.id ?? null,
        allowAlcohol: payload.restaurant?.allowAlcohol ?? prev.restaurant?.allowAlcohol ?? false,
        allowedNow: payload.restaurant?.allowedNow ?? prev.restaurant?.allowedNow ?? false,
        verifyAgeText: payload.restaurant?.verifyAgeText ?? prev.restaurant?.verifyAgeText ?? '',
        salesDisabledText: payload.restaurant?.salesDisabledText ?? prev.restaurant?.salesDisabledText ?? '',
        policyBlockedText: payload.restaurant?.policyBlockedText ?? prev.restaurant?.policyBlockedText ?? ''
      },
      participants: {
        orderParticipantId: payload.participants?.orderParticipantId ?? prev.participants?.orderParticipantId ?? null,
        menuParticipantId: payload.participants?.menuParticipantId ?? prev.participants?.menuParticipantId ?? null
      },
      version: payload.version ?? prev.version
    };
    this.state = next;
  }

  connect() {
    this.applyDatasetState();
    this.dispatchState();

    // Initial JSON fetch to hydrate items/totals on first load
    try {
      const slug = document.body?.dataset?.smartmenuId;
      const needsHydration = () => {
        const gs = window.__SM_STATE || {};
        // Hydration needed if flags not present or totals missing
        return !gs.flags || typeof gs.flags.displayRequestBill === 'undefined' || !gs.totals;
      };
      const doHydrate = () => {
        if (!slug) return;
        const url = `/smartmenus/${encodeURIComponent(slug)}.json?ts=${Date.now()}`;
        fetch(url, { headers: { Accept: 'application/json', 'Cache-Control': 'no-cache', Pragma: 'no-cache' } })
          .then((r) => (r && r.ok ? r.json() : null))
          .then((payload) => {
            if (payload) {
              try {
                const cnt = Array.isArray(payload?.order?.items) ? payload.order.items.length : 0;
                console.info('[State][hydrate] items=', cnt, 'orderId=', payload?.order?.id, 'hasTotals=', !!payload?.totals);
              } catch (_) {}
              this.applyJsonState(payload);
              this.dispatchState();
            }
          })
          .catch(() => {});
      };

      // Always hydrate if state is not yet hydrated (even if a previous page set __SM_INIT_FETCHED)
      if (needsHydration()) { doHydrate(); }

      // Rehydrate on BFCache restore
      if (!window.__SM_PAGESHOW_BOUND) {
        window.__SM_PAGESHOW_BOUND = true;
        window.addEventListener('pageshow', (evt) => {
          // evt.persisted is true when restored from bfcache
          if (evt?.persisted || needsHydration()) { doHydrate(); }
        });
      }

      // Rehydrate on visibility change to visible if not hydrated yet
      if (!window.__SM_VISIBILITY_BOUND) {
        window.__SM_VISIBILITY_BOUND = true;
        document.addEventListener('visibilitychange', () => {
          if (document.visibilityState === 'visible' && needsHydration()) {
            doHydrate();
          }
        });
      }
    } catch (_) {}

    // Listen for JSON state updates from the channel
    this._onStateUpdate = (e) => {
      try {
        const incoming = e.detail || {};
        try {
          const cnt = Array.isArray(incoming?.order?.items) ? incoming.order.items.length : 0;
          console.info('[State][update] items=', cnt, 'orderId=', incoming?.order?.id, 'hasTotals=', !!incoming?.totals);
        } catch (_) {}
        this.applyJsonState(incoming);
        this.dispatchState();
      } catch (err) {
        console.error('[StateController] Failed to apply JSON state update', err);
      }
    };
    document.addEventListener('state:update', this._onStateUpdate);

    // Observe attribute changes on the context container (if replaced/updated)
    this.observer = new MutationObserver((mutations) => {
      for (const m of mutations) {
        if (m.type === 'attributes' && m.attributeName?.startsWith('data-')) {
          this.applyDatasetState();
          this.dispatchState();
          break;
        }
      }
    });
    this.observer.observe(this.element, { attributes: true });
  }

  disconnect() {
    if (this.observer) this.observer.disconnect();
    if (this._onStateUpdate) document.removeEventListener('state:update', this._onStateUpdate);
  }

  // Build state object from dataset
  applyDatasetState() {
    const d = this.element.dataset || {};
    this.state = {
      session: d.session || null,
      order: {
        id: d.orderId || null,
        status: (d.orderStatus || '').toLowerCase() || null
      },
      totals: null,
      tableId: d.tableId || null,
      employeeId: d.employeeId || null,
      menuId: d.menuId || null,
      restaurant: {
        id: d.restaurantId || null,
        allowAlcohol: d.allowAlcohol === '1',
        allowedNow: d.alcoholAllowedNow === '1',
        verifyAgeText: d.alcoholVerifyAgeText || '',
        salesDisabledText: d.alcoholSalesDisabledText || '',
        policyBlockedText: d.alcoholPolicyBlockedText || ''
      },
      participants: {
        orderParticipantId: d.participantId || null,
        menuParticipantId: d.menuParticipantId || null
      }
    };
  }


  // Dispatch broad and targeted events for other controllers
  dispatchState() {
    try { window.__SM_STATE = this.state; } catch (_) {}
    this.dispatch('changed', { detail: this.state });
    this.dispatch('order', { detail: this.state.order });
    this.dispatch('menu', { detail: { menuId: this.state.menuId } });
    this.dispatch('flags', { detail: { restaurant: this.state.restaurant } });

    // Compatibility with existing listeners
    try {
      document.dispatchEvent(new CustomEvent('state:changed', { detail: this.state }));
      document.dispatchEvent(new CustomEvent('state:order', { detail: this.state.order }));
      document.dispatchEvent(new CustomEvent('state:menu', { detail: { menuId: this.state.menuId } }));
      document.dispatchEvent(new CustomEvent('state:flags', { detail: { restaurant: this.state.restaurant } }));

      // bridge to old events if any code still listens
      document.dispatchEvent(new CustomEvent('ordr:updated'));
      document.dispatchEvent(new CustomEvent('ordr:order:updated'));
    } catch (_) {}
  }
}
