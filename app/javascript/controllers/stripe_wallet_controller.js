import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    openOrderId: Number,
    amountCents: Number,
    currency: String,
  };

  connect() {
    const pkMeta = document.querySelector('meta[name="stripe-publishable-key"]');
    const pk = pkMeta && pkMeta.content;
    if (!pk) return;

    this._initStripe(pk);
  }

  async _initStripe(pk) {
    if (!window.Stripe) {
      try {
        await this._loadStripeScript();
      } catch (e) {
        return;
      }
    }

    this.stripe = window.Stripe(pk);
    const pr = this.stripe.paymentRequest({
      country: (this.currencyValue || 'usd').toUpperCase() === 'USD' ? 'US' : 'GB',
      currency: (this.currencyValue || 'usd').toLowerCase(),
      total: { label: 'Bill Total', amount: this.amountCentsValue || 0 },
      requestPayerName: true,
      requestPayerEmail: true,
    });

    const elements = this.stripe.elements();
    pr.canMakePayment().then((result) => {
      if (result) {
        const prButton = elements.create('paymentRequestButton', {
          paymentRequest: pr,
          style: { paymentRequestButton: { type: 'default', theme: 'dark', height: '48px' } },
        });
        prButton.mount(this.element);
      }
    });

    pr.on('paymentmethod', async (ev) => {
      try {
        const tipCents = this._readTipCents();
        const amount = (this.amountCentsValue || 0) + tipCents;
        const clientSecret = await this._createIntent(amount);
        const { paymentIntent, error } = await this.stripe.confirmCardPayment(
          clientSecret,
          { payment_method: ev.paymentMethod.id },
          { handleActions: false }
        );
        if (error) {
          ev.complete('fail');
          return;
        }
        ev.complete('success');
        if (paymentIntent.status === 'requires_action') {
          const { error: actionError } = await this.stripe.confirmCardPayment(clientSecret);
          if (actionError) return;
        }
        this._notifySuccess();
      } catch (e) {
        ev.complete('fail');
      }
    });
  }

  _readTipCents() {
    const tipEl = document.getElementById('tipNumberField');
    if (!tipEl) return 0;
    const v = parseFloat(tipEl.value || '0');
    if (Number.isNaN(v)) return 0;
    return Math.round(v * 100);
  }

  async _createIntent(amountCents) {
    const res = await fetch('/payments/create_intent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        open_order_id: this.openOrderIdValue,
        amount: amountCents,
        currency: (this.currencyValue || 'usd').toLowerCase(),
      }),
    });
    const data = await res.json();
    return data.client_secret;
  }

  _loadStripeScript() {
    if (this._stripePromise) return this._stripePromise;
    this._stripePromise = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "https://js.stripe.com/v3";
      script.async = true;
      script.onload = () => resolve();
      script.onerror = () => reject(new Error("Failed to load Stripe.js"));
      document.head.appendChild(script);
    });
    return this._stripePromise;
  }

  _notifySuccess() {
    const el = document.getElementById('pay-order');
    if (el) {
      el.click();
    }
  }
}
