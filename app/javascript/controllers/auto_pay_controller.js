import { Controller } from '@hotwired/stimulus';

// AutoPayController: staff-facing order header badges and controls.
// - Shows "Payment on File", "Bill Viewed", "Auto-Pay Armed" badges
// - Provides "Disable Auto-Pay" and "Charge Now" buttons
// - Handles ActionCable auto_pay_succeeded / auto_pay_failed events (dispatched by state_controller)
export default class extends Controller {
  static targets = [
    'paymentOnFileBadge',
    'billViewedBadge',
    'autoPayArmedBadge',
    'disableAutoPayBtn',
    'chargeNowBtn',
    'statusMessage',
  ];

  static values = {
    restaurantId: Number,
    ordrId: Number,
    paymentOnFile: Boolean,
    billViewed: Boolean,
    autoPayEnabled: Boolean,
    autoPayStatus: String,
  };

  connect() {
    this._updateBadges();
    // Store bound references so the same function objects are passed to removeEventListener
    this._boundOnSucceeded = this._onSucceeded.bind(this);
    this._boundOnFailed = this._onFailed.bind(this);
    // Listen for real-time auto_pay events broadcast via ActionCable → state controller
    this.element.addEventListener('auto_pay:succeeded', this._boundOnSucceeded);
    this.element.addEventListener('auto_pay:failed', this._boundOnFailed);
  }

  disconnect() {
    this.element.removeEventListener('auto_pay:succeeded', this._boundOnSucceeded);
    this.element.removeEventListener('auto_pay:failed', this._boundOnFailed);
  }

  // Called when staff clicks "Disable Auto-Pay"
  async disableAutoPay(event) {
    event.preventDefault();
    this._setLoading(true);

    try {
      const res = await fetch(this._autoPayUrl(), {
        method: 'POST',
        headers: this._headers(),
        body: JSON.stringify({ enabled: false }),
      });
      const data = await res.json();

      if (data.ok) {
        this.autoPayEnabledValue = false;
        this._updateBadges();
        this._showStatus('Auto-pay disabled.', 'info');
      } else {
        this._showStatus(data.error || 'Failed to disable auto-pay.', 'danger');
      }
    } catch (e) {
      this._showStatus('Network error. Please try again.', 'danger');
    } finally {
      this._setLoading(false);
    }
  }

  // Called when staff clicks "Charge Now"
  async chargeNow(event) {
    event.preventDefault();
    if (!confirm('Charge the customer now?')) return;

    this._setLoading(true);

    try {
      const res = await fetch(this._captureUrl(), {
        method: 'POST',
        headers: this._headers(),
        body: JSON.stringify({}),
      });
      const data = await res.json();

      if (data.ok) {
        this.autoPayStatusValue = 'succeeded';
        this._updateBadges();
        this._showStatus('Payment captured successfully.', 'success');
      } else {
        this._showStatus(data.error || 'Capture failed.', 'danger');
      }
    } catch (e) {
      this._showStatus('Network error. Please try again.', 'danger');
    } finally {
      this._setLoading(false);
    }
  }

  // Triggered by state:update event when auto_pay_succeeded arrives via ActionCable
  _onSucceeded() {
    this.autoPayStatusValue = 'succeeded';
    this._updateBadges();
    this._showStatus('Auto-pay captured.', 'success');
  }

  // Triggered by state:update event when auto_pay_failed arrives via ActionCable
  _onFailed(e) {
    this.autoPayStatusValue = 'failed';
    this._updateBadges();
    const reason = e.detail?.failure_reason || 'Payment failed';
    this._showStatus(`Auto-pay failed: ${reason}`, 'danger');
  }

  _updateBadges() {
    this._toggle('paymentOnFileBadge', this.paymentOnFileValue);
    this._toggle('billViewedBadge', this.billViewedValue);
    this._toggle(
      'autoPayArmedBadge',
      this.autoPayEnabledValue && this.autoPayStatusValue !== 'succeeded'
    );
    this._toggle(
      'disableAutoPayBtn',
      this.autoPayEnabledValue && this.autoPayStatusValue !== 'succeeded'
    );
    this._toggle(
      'chargeNowBtn',
      this.paymentOnFileValue && this.autoPayStatusValue !== 'succeeded'
    );
  }

  _toggle(targetName, show) {
    const key = `${targetName}Target`;
    if (!this.hasTarget(targetName)) return;
    this[key].classList.toggle('d-none', !show);
  }

  hasTarget(name) {
    return this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`];
  }

  _showStatus(message, type = 'info') {
    if (!this.hasStatusMessageTarget) return;
    this.statusMessageTarget.textContent = message;
    this.statusMessageTarget.className = `alert alert-${type} mt-1 py-1 px-2 small`;
    this.statusMessageTarget.classList.remove('d-none');

    clearTimeout(this._statusTimeout);
    this._statusTimeout = setTimeout(() => {
      this.statusMessageTarget.classList.add('d-none');
    }, 5000);
  }

  _setLoading(loading) {
    const btns = [
      this.hasDisableAutoPayBtnTarget ? this.disableAutoPayBtnTarget : null,
      this.hasChargeNowBtnTarget ? this.chargeNowBtnTarget : null,
    ].filter(Boolean);

    btns.forEach((btn) => {
      btn.disabled = loading;
    });
  }

  _autoPayUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/auto_pay`;
  }

  _captureUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/capture`;
  }

  _headers() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': meta ? meta.content : '',
    };
  }
}
