import { Controller } from '@hotwired/stimulus';

/**
 * CollectPayment Stimulus Controller
 *
 * Manages the staff-facing "Collect Payment" modal. Provides three payment paths:
 *
 * 1. QR Code — generates a hosted checkout URL (Stripe/Square) and displays it
 *    as a QR code for the customer to scan on their own device.
 *
 * 2. Cash — marks the order as paid in cash and closes it server-side.
 *
 * 3. Square POS (Tap to Pay) — deep-links into the Square Point of Sale app
 *    on the staff's mobile device to process a card-present or Tap to Pay
 *    transaction. Only rendered for Square restaurants.
 *
 * Usage:
 *   <div data-controller="collect-payment"
 *        data-collect-payment-cash-url-value="/restaurants/1/ordrs/2/payments/cash"
 *        data-collect-payment-qr-url-value="/restaurants/1/ordrs/2/payments/checkout_qr"
 *        data-collect-payment-amount-cents-value="2500"
 *        data-collect-payment-currency-value="EUR"
 *        data-collect-payment-order-id-value="2"
 *        data-collect-payment-square-app-id-value="sq0idp-..."
 *        data-collect-payment-square-pos-available-value="true">
 */
export default class extends Controller {
  #qrLoaded = false;

  static targets = ['qrContainer', 'qrImage', 'qrSpinner', 'qrError', 'cashButton', 'cashSpinner', 'cashSuccess', 'squarePosButton', 'statusMessage'];

  static values = {
    cashUrl: String,
    qrUrl: String,
    amountCents: Number,
    currency: { type: String, default: 'EUR' },
    orderId: String,
    squareAppId: String,
    squarePosAvailable: { type: Boolean, default: false },
  };

  connect() {
    this.#wireTabActivation();
  }

  // ── Tab activation ──────────────────────────────────────────────────

  #wireTabActivation() {
    // Listen for Bootstrap tab shown events on the parent modal
    const modal = this.element.closest('.modal') || document;
    modal.addEventListener('shown.bs.tab', (e) => {
      const target = e.target?.dataset?.bsTarget || e.target?.getAttribute('href');

      // Lazy-load QR when that tab becomes active
      if (target === '#collect-qr-pane') {
        this.#loadQr();
      }

      // Show/hide the card-only footer confirm button
      const footer = document.getElementById('payOrderModalFooter');
      if (footer) {
        footer.classList.toggle('d-none', target !== '#collect-card-pane');
      }
    });
  }

  // ── QR Code ─────────────────────────────────────────────────────────

  loadQr() {
    this.#loadQr();
  }

  async #loadQr() {
    if (!this.hasQrContainerTarget) return;
    if (this.#qrLoaded) return;

    this.#setQrLoading(true);

    try {
      const resp = await fetch(this.qrUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
        },
        body: JSON.stringify({
          success_url: window.location.href,
          cancel_url: window.location.href,
        }),
      });

      const data = await resp.json();

      if (!data.ok) {
        this.#showQrError(data.error || 'Could not generate payment link');
        return;
      }

      this.#qrLoaded = true;
      this.#renderQr(data.qr_svg, data.checkout_url);
    } catch (e) {
      console.error('[CollectPayment] QR load failed:', e);
      this.#showQrError('Failed to load payment QR. Please try again.');
    } finally {
      this.#setQrLoading(false);
    }
  }

  #renderQr(svgString, checkoutUrl) {
    if (!this.hasQrImageTarget) return;

    const wrapper = this.qrImageTarget;
    wrapper.innerHTML = svgString;
    wrapper.querySelector('svg')?.setAttribute('class', 'collect-payment-qr');

    // Show copy/open link below QR
    const existing = wrapper.nextElementSibling;
    if (existing && existing.classList.contains('qr-link-row')) return;

    const linkRow = document.createElement('div');
    linkRow.className = 'qr-link-row mt-2 d-flex gap-2 justify-content-center flex-wrap';
    linkRow.innerHTML = `
      <a href="${checkoutUrl}" target="_blank" rel="noopener noreferrer" class="btn btn-sm btn-outline-secondary">
        <i class="bi bi-box-arrow-up-right"></i> Open link
      </a>
      <button type="button" class="btn btn-sm btn-outline-secondary js-copy-link" data-url="${checkoutUrl}">
        <i class="bi bi-clipboard"></i> Copy link
      </button>
    `;
    linkRow.querySelector('.js-copy-link')?.addEventListener('click', (e) => {
      navigator.clipboard?.writeText(checkoutUrl).then(() => {
        e.currentTarget.innerHTML = '<i class="bi bi-check"></i> Copied!';
        setTimeout(() => {
          e.currentTarget.innerHTML = '<i class="bi bi-clipboard"></i> Copy link';
        }, 2000);
      });
    });

    wrapper.insertAdjacentElement('afterend', linkRow);
  }

  #setQrLoading(loading) {
    if (this.hasQrSpinnerTarget) {
      this.qrSpinnerTarget.classList.toggle('d-none', !loading);
    }
    if (this.hasQrImageTarget) {
      this.qrImageTarget.classList.toggle('d-none', loading);
    }
  }

  #showQrError(message) {
    if (this.hasQrErrorTarget) {
      this.qrErrorTarget.textContent = message;
      this.qrErrorTarget.classList.remove('d-none');
    }
  }

  // ── Cash Payment ────────────────────────────────────────────────────

  async cashPayment(event) {
    event?.preventDefault();

    if (this.hasCashButtonTarget) {
      this.cashButtonTarget.disabled = true;
    }
    if (this.hasCashSpinnerTarget) {
      this.cashSpinnerTarget.classList.remove('d-none');
    }

    try {
      const resp = await fetch(this.cashUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
        },
        body: JSON.stringify({}),
      });

      const data = await resp.json();

      if (data.ok) {
        this.#showCashSuccess();
        this.element.dispatchEvent(new CustomEvent('collect-payment:cash-paid', { bubbles: true }));
      } else {
        alert(data.error || 'Failed to record cash payment. Please try again.');
        if (this.hasCashButtonTarget) this.cashButtonTarget.disabled = false;
      }
    } catch (e) {
      console.error('[CollectPayment] Cash payment failed:', e);
      alert('Failed to record cash payment. Please try again.');
      if (this.hasCashButtonTarget) this.cashButtonTarget.disabled = false;
    } finally {
      if (this.hasCashSpinnerTarget) {
        this.cashSpinnerTarget.classList.add('d-none');
      }
    }
  }

  #showCashSuccess() {
    if (this.hasCashButtonTarget) {
      this.cashButtonTarget.innerHTML = '<i class="bi bi-check-circle"></i> Paid (Cash)';
      this.cashButtonTarget.classList.remove('btn-success');
      this.cashButtonTarget.classList.add('btn-outline-success');
      this.cashButtonTarget.disabled = true;
    }
    if (this.hasCashSuccessTarget) {
      this.cashSuccessTarget.classList.remove('d-none');
    }
  }

  // ── Square POS Deep-link ─────────────────────────────────────────────

  openSquarePos(event) {
    event?.preventDefault();

    if (!this.squarePosAvailableValue) return;

    const amountCents = this.amountCentsValue;
    const currency = (this.currencyValue || 'USD').toUpperCase();
    const orderId = this.orderIdValue;

    const posData = JSON.stringify({
      amount_money: { amount: amountCents, currency_code: currency },
      callback_url: `${window.location.origin}/restaurants/payment-complete?order_id=${orderId}`,
      client_id: this.squareAppIdValue,
      version: '1.3',
      note: `Order #${orderId}`,
      options: {
        supported_tender_types: ['CREDIT_CARD', 'CASH', 'OTHER', 'SQUARE_GIFT_CARD', 'CARD_ON_FILE'],
      },
    });

    const encoded = btoa(unescape(encodeURIComponent(posData)));
    const deepLink = `square-commerce-v1://payment/create?data=${encodeURIComponent(encoded)}`;

    window.location.href = deepLink;

    // If Square POS app is not installed the deep-link silently fails on most devices.
    // Show a fallback message after a short delay.
    setTimeout(() => {
      if (this.hasSquarePosButtonTarget) {
        this.squarePosButtonTarget.innerHTML =
          '<i class="bi bi-exclamation-triangle"></i> Square POS app not found';
        this.squarePosButtonTarget.classList.add('btn-outline-warning');
        this.squarePosButtonTarget.classList.remove('btn-warning');
      }
    }, 2500);
  }
}
