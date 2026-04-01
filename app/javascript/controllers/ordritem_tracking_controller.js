import { Controller } from '@hotwired/stimulus';
import consumer from '../channels/consumer';

// Connects to data-controller="ordritem-tracking"
// Receives order_item_status_changed broadcasts from OrdrChannel and
// updates item badges + order summary label without a page reload.
export default class extends Controller {
  static targets = ['orderSummaryLabel', 'orderSummaryStatus'];
  static values = { orderId: String };

  connect() {
    if (!this.orderIdValue) return;

    this._subscription = consumer.subscriptions.create(
      { channel: 'OrdrChannel', order_id: this.orderIdValue },
      {
        received: (data) => this._handleReceived(data),
        disconnected: () => this._handleDisconnect(),
      }
    );
  }

  disconnect() {
    if (this._subscription) {
      this._subscription.unsubscribe();
      this._subscription = null;
    }
  }

  _handleReceived(data) {
    if (data.type !== 'order_item_status_changed') return;

    this._updateItemBadge(data);
    this._updateOrderSummary(data);
  }

  _updateItemBadge(data) {
    const ordritemId = data.ordritem_id;
    const toStatus = data.to_status;
    const el = this.element.querySelector(`[data-ordritem-id="${ordritemId}"]`);
    if (!el) return;

    // Update badge class and text
    const badge = el.querySelector('[data-ordritem-status-badge]');
    if (badge) {
      badge.textContent = this._humanise(toStatus);
      badge.className = `badge ordritem-status-badge ordritem-status-badge--${toStatus}`;
      badge.dataset.status = toStatus;
    }

    // Show "Updated just now" timestamp label
    const ts = el.querySelector('[data-ordritem-updated-at]');
    if (ts) {
      ts.textContent = 'Updated just now';
      ts.style.display = '';
    }
  }

  _updateOrderSummary(data) {
    if (!data.order_summary) return;

    if (this.hasOrderSummaryLabelTarget) {
      this.orderSummaryLabelTarget.textContent = data.order_summary.label;
    }
    if (this.hasOrderSummaryStatusTarget) {
      this.orderSummaryStatusTarget.dataset.summaryStatus = data.order_summary.status;
    }
  }

  // On reconnect, reload the order status partial via Turbo Frame to reconcile
  // any missed broadcasts during the disconnected period.
  _handleDisconnect() {
    const frame = document.getElementById(`ordr-status-frame-${this.orderIdValue}`);
    if (frame) {
      frame.reload();
    }
  }

  _humanise(status) {
    const map = {
      pending: 'Received',
      preparing: 'Preparing',
      ready: 'Ready',
      collected: 'Collected',
    };
    return map[status] || status;
  }
}
