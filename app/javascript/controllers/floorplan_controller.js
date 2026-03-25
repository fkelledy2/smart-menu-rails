import { Controller } from '@hotwired/stimulus';
import { createConsumer } from '@rails/actioncable';

// FloorplanController: real-time table grid for the staff floorplan dashboard.
// Responsibilities:
//   - Subscribe to FloorplanChannel via ActionCable
//   - Replace individual table tile DOM nodes when the server broadcasts an update
//   - Apply client-side filters (all / active / billrequested / delayed)
//   - Tick elapsed-time counters every minute without a server round-trip
export default class extends Controller {
  static targets = ['filterBtn', 'tileGrid', 'tileWrapper'];

  static values = {
    restaurantId: Number,
  };

  connect() {
    this._activeFilter = 'all';
    this._subscribeToChannel();
    this._startElapsedTimer();
  }

  disconnect() {
    if (this._subscription) {
      this._subscription.unsubscribe();
    }
    if (this._elapsedTimer) {
      clearInterval(this._elapsedTimer);
    }
  }

  // Filter button clicked
  applyFilter(event) {
    const btn = event.currentTarget;
    const filter = btn.dataset.filter;
    this._activeFilter = filter;

    // Update active button styling
    this.filterBtnTargets.forEach((b) => {
      b.classList.toggle('btn-primary', b.dataset.filter === filter);
      b.classList.toggle('btn-outline-secondary', b.dataset.filter !== filter);
    });

    this._applyClientFilter();
  }

  // Private

  _subscribeToChannel() {
    const consumer = createConsumer();
    this._subscription = consumer.subscriptions.create(
      {
        channel: 'FloorplanChannel',
        restaurant_id: this.restaurantIdValue,
      },
      {
        received: (data) => this._handleBroadcast(data),
      }
    );
  }

  _handleBroadcast(data) {
    if (data.type !== 'tile_update' || !data.html || !data.tablesetting_id) return;

    // Replace the inner tile DOM node (id="table-tile-{id}") with the server-rendered HTML.
    const tileId = `table-tile-${data.tablesetting_id}`;
    const existingTile = document.getElementById(tileId);
    if (!existingTile) return;

    const template = document.createElement('template');
    template.innerHTML = data.html.trim();
    const newTile = template.content.firstElementChild;
    if (!newTile) return;

    existingTile.replaceWith(newTile);

    // Update the wrapper's data-status and data-delayed attributes so filters work.
    const wrapper = newTile.closest('[data-floorplan-target="tileWrapper"]');
    if (wrapper) {
      const filterStatus = newTile.dataset.filterStatus || 'available';
      wrapper.dataset.status = filterStatus;
      // Delayed badge is present if the tile contains a "Delayed" badge element.
      wrapper.dataset.delayed = newTile.querySelector('.badge.bg-warning') ? 'true' : 'false';
    }

    // Re-apply the current filter after DOM update
    requestAnimationFrame(() => this._applyClientFilter());
  }

  _applyClientFilter() {
    const filter = this._activeFilter;
    this.tileWrapperTargets.forEach((wrapper) => {
      const status = wrapper.dataset.status;
      const delayed = wrapper.dataset.delayed === 'true';
      let visible = false;

      switch (filter) {
        case 'all':
          visible = true;
          break;
        case 'active':
          visible = status !== 'available' && status !== 'paid' && status !== 'closed';
          break;
        case 'billrequested':
          visible = status === 'billrequested';
          break;
        case 'delayed':
          visible = delayed;
          break;
        default:
          visible = true;
      }

      wrapper.classList.toggle('d-none', !visible);
    });
  }

  // Tick elapsed time counters every 60 seconds
  _startElapsedTimer() {
    this._tickElapsed();
    this._elapsedTimer = setInterval(() => this._tickElapsed(), 60_000);
  }

  _tickElapsed() {
    document.querySelectorAll('.floorplan-elapsed-time').forEach((el) => {
      const openedAt = el.dataset.openedAt;
      if (!openedAt) return;
      const minutes = Math.floor((Date.now() - new Date(openedAt).getTime()) / 60_000);
      if (minutes < 1) {
        el.textContent = 'just now';
      } else if (minutes < 60) {
        el.textContent = `${minutes} min`;
      } else {
        const hours = Math.floor(minutes / 60);
        el.textContent = `${hours}h ${minutes % 60}m`;
      }
    });
  }
}
