import { Controller } from '@hotwired/stimulus';

// WaitTimeController: auto-refreshes wait time estimates every 5 minutes.
// Updates the "last updated" badge and queue count badge on re-render.
export default class extends Controller {
  static targets = ['lastUpdated', 'queueCount'];

  static values = {
    restaurantId: Number,
  };

  connect() {
    this._startRefreshTimer();
  }

  disconnect() {
    if (this._refreshTimer) {
      clearInterval(this._refreshTimer);
    }
  }

  // Called by Turbo after a stream update to refresh displayed count.
  updateQueueCount(count) {
    if (this.hasQueueCountTarget) {
      this.queueCountTarget.textContent = count;
    }
  }

  _startRefreshTimer() {
    // Turbo polling handles estimate refresh — 5 minute interval.
    // We track time since last update visually.
    this._updatedAt = Date.now();
    this._refreshTimer = setInterval(() => this._tickLastUpdated(), 60_000);
  }

  _tickLastUpdated() {
    if (!this.hasLastUpdatedTarget) return;
    const minutes = Math.floor((Date.now() - this._updatedAt) / 60_000);
    this.lastUpdatedTarget.textContent =
      minutes === 0 ? 'Updated just now' : `Updated ${minutes}m ago`;
  }
}
