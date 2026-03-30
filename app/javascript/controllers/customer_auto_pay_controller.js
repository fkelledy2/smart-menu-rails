import { Controller } from '@hotwired/stimulus';

// CustomerAutoPayController: customer-facing auto-pay setup in the SmartMenu.
// Handles:
//  - Loading and mounting Stripe Elements (Payment Element) to collect a card
//  - Storing the resulting PaymentMethod ID to the server (no raw PAN)
//  - Enabling / disabling auto-pay toggle with consent dialog
//  - Recording bill view events
export default class extends Controller {
  static targets = [
    'stripeContainer',
    'addCardBtn',
    'removeCardBtn',
    'autoPayToggle',
    'consentSection',
    'paymentOnFileIndicator',
    'statusMessage',
    'submitCardBtn',
    'billSection',
  ];

  static values = {
    restaurantId: Number,
    ordrId: Number,
    stripePublishableKey: String,
    paymentOnFile: Boolean,
    autoPayEnabled: Boolean,
    autoPayStatus: String,
    currency: String,
    amountCents: Number,
  };

  connect() {
    if (this.hasAutoPayEnabledValue) {
      this._updateUI();
    }

    // Record bill view on connect (idempotent server-side)
    if (this.hasBillSectionTarget) {
      this._recordBillView();
    }

    // Listen for server-side auto_pay_disarmed broadcast (e.g. order total changed)
    this._boundOnDisarmed = this._onDisarmed.bind(this);
    this.element.addEventListener('auto_pay:disarmed', this._boundOnDisarmed);
  }

  disconnect() {
    clearTimeout(this._statusTimeout);
    if (this._boundOnDisarmed) {
      this.element.removeEventListener('auto_pay:disarmed', this._boundOnDisarmed);
    }
  }

  // Add card button clicked — show Stripe Elements
  async showAddCard(event) {
    event.preventDefault();
    if (!this.stripePublishableKeyValue) {
      this._showStatus('Payment setup not available.', 'danger');
      return;
    }

    await this._initStripe();
    this.stripeContainerTarget.classList.remove('d-none');
    this.addCardBtnTarget.classList.add('d-none');
  }

  // Submit card (Stripe Elements confirm → obtain PaymentMethod ID)
  async submitCard(event) {
    event.preventDefault();
    this._setLoading(true);

    try {
      const { setupIntent, error } = await this.stripe.confirmSetup({
        elements: this.stripeElements,
        redirect: 'if_required',
      });

      if (error) {
        this._showStatus(error.message || 'Card setup failed.', 'danger');
        return;
      }

      const paymentMethodId = setupIntent?.payment_method;
      if (!paymentMethodId) {
        this._showStatus('Could not retrieve payment method. Please try again.', 'danger');
        return;
      }

      await this._storePaymentMethod(paymentMethodId);
    } catch (e) {
      this._showStatus('Unexpected error. Please try again.', 'danger');
    } finally {
      this._setLoading(false);
    }
  }

  // Remove payment method
  async removeCard(event) {
    event.preventDefault();
    if (!confirm('Remove your saved payment method? Auto-pay will be disabled.')) return;

    this._setLoading(true);
    try {
      const res = await fetch(this._paymentMethodsUrl(), {
        method: 'DELETE',
        headers: this._headers(),
      });
      const data = await res.json();

      if (data.ok) {
        this.paymentOnFileValue = false;
        this.autoPayEnabledValue = false;
        this._updateUI();
        this._showStatus('Payment method removed.', 'info');
      } else {
        this._showStatus(data.error || 'Failed to remove payment method.', 'danger');
      }
    } catch (e) {
      this._showStatus('Network error. Please try again.', 'danger');
    } finally {
      this._setLoading(false);
    }
  }

  // Auto-pay toggle changed
  async toggleAutoPay(event) {
    const enabled = event.target.checked;

    if (enabled) {
      const confirmed = confirm(
        'Enable auto-pay? When the restaurant marks your order ready to pay, ' +
          'your saved card will be charged automatically.'
      );
      if (!confirmed) {
        event.target.checked = false;
        return;
      }
    }

    this._setLoading(true);
    try {
      const res = await fetch(this._autoPayUrl(), {
        method: 'POST',
        headers: this._headers(),
        body: JSON.stringify({ enabled }),
      });
      const data = await res.json();

      if (data.ok) {
        this.autoPayEnabledValue = data.auto_pay_enabled;
        this._updateUI();
        const msg = data.auto_pay_enabled ? 'Auto-pay enabled.' : 'Auto-pay disabled.';
        this._showStatus(msg, 'success');
      } else {
        event.target.checked = !enabled;
        this._showStatus(data.error || 'Failed to update auto-pay.', 'danger');
      }
    } catch (e) {
      event.target.checked = !enabled;
      this._showStatus('Network error. Please try again.', 'danger');
    } finally {
      this._setLoading(false);
    }
  }

  // Called when the server broadcasts auto_pay_disarmed (e.g. order total changed)
  _onDisarmed() {
    this.autoPayEnabledValue = false;
    this._updateUI();
    this._showStatus(
      'Auto-pay has been turned off because your order total changed. Please review your total and re-enable if you wish.',
      'warning'
    );
  }

  // Private

  async _initStripe() {
    if (this.stripe) return;

    if (!window.Stripe) {
      await this._loadStripeScript();
    }

    this.stripe = window.Stripe(this.stripePublishableKeyValue);

    // Use SetupIntent flow so we only store the payment method, not charge immediately
    // The actual charge happens server-side via AutoPay::CaptureService
    const res = await fetch(this._setupIntentUrl(), {
      method: 'POST',
      headers: this._headers(),
      body: JSON.stringify({}),
    });
    const data = await res.json();

    if (!data.client_secret) {
      throw new Error('Could not create payment setup session.');
    }

    this.stripeElements = this.stripe.elements({
      clientSecret: data.client_secret,
      appearance: { theme: 'stripe' },
    });

    const paymentElement = this.stripeElements.create('payment');
    paymentElement.mount(this.stripeContainerTarget);
  }

  async _storePaymentMethod(paymentMethodId) {
    const res = await fetch(this._paymentMethodsUrl(), {
      method: 'POST',
      headers: this._headers(),
      body: JSON.stringify({ payment_method_id: paymentMethodId }),
    });
    const data = await res.json();

    if (data.ok) {
      this.paymentOnFileValue = true;
      this.stripeContainerTarget.classList.add('d-none');
      this._updateUI();
      this._showStatus('Card saved. You can now enable auto-pay.', 'success');
    } else {
      this._showStatus(data.error || 'Failed to save payment method.', 'danger');
    }
  }

  async _recordBillView() {
    try {
      await fetch(this._viewBillUrl(), {
        method: 'POST',
        headers: this._headers(),
        body: JSON.stringify({}),
      });
    } catch (_e) {
      // Non-critical — silently ignore
    }
  }

  _updateUI() {
    this._toggle('paymentOnFileIndicator', this.paymentOnFileValue);
    this._toggle('addCardBtn', !this.paymentOnFileValue);
    this._toggle('removeCardBtn', this.paymentOnFileValue);
    this._toggle(
      'consentSection',
      this.paymentOnFileValue && this.autoPayStatusValue !== 'succeeded'
    );

    if (this.hasAutoPayToggleTarget) {
      this.autoPayToggleTarget.checked = this.autoPayEnabledValue;
      this.autoPayToggleTarget.disabled =
        !this.paymentOnFileValue || this.autoPayStatusValue === 'succeeded';
    }
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
    this.statusMessageTarget.className = `alert alert-${type} mt-2 py-1 px-2 small`;
    this.statusMessageTarget.classList.remove('d-none');

    clearTimeout(this._statusTimeout);
    this._statusTimeout = setTimeout(() => {
      this.statusMessageTarget.classList.add('d-none');
    }, 6000);
  }

  _setLoading(loading) {
    const btns = document.querySelectorAll('[data-customer-auto-pay-target]');
    btns.forEach((btn) => {
      if (btn.tagName === 'BUTTON') btn.disabled = loading;
    });
  }

  _paymentMethodsUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/payment_methods`;
  }

  _autoPayUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/auto_pay`;
  }

  _viewBillUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/view_bill`;
  }

  _setupIntentUrl() {
    return `/restaurants/${this.restaurantIdValue}/ordrs/${this.ordrIdValue}/payments/setup_intent`;
  }

  _headers() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': meta ? meta.content : '',
    };
  }

  _loadStripeScript() {
    if (this._stripePromise) return this._stripePromise;
    this._stripePromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://js.stripe.com/v3';
      script.async = true;
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Failed to load Stripe.js'));
      document.head.appendChild(script);
    });
    return this._stripePromise;
  }
}
