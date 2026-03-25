import { Controller } from '@hotwired/stimulus';

// Handles the customer self-service receipt request form on the SmartMenu.
// Submits via fetch to POST /receipts/request and shows inline success/error feedback.
export default class extends Controller {
  static targets = ['form', 'emailInput', 'submitButton', 'status'];

  async submit(event) {
    event.preventDefault();

    const form = this.formTarget;
    const email = this.emailInputTarget.value.trim();
    const button = this.submitButtonTarget;

    if (!this.#validateEmail(email)) {
      this.#showStatus('Please enter a valid email address.', 'error');
      return;
    }

    const consentCheckbox = form.querySelector('[name="consent"]');
    if (consentCheckbox && !consentCheckbox.checked) {
      this.#showStatus('Please confirm your consent to receive this receipt.', 'error');
      return;
    }

    button.disabled = true;
    button.textContent = 'Sending...';
    this.#showStatus('', 'hidden');

    try {
      const formData = new FormData(form);
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

      const response = await fetch('/receipts/request', {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken || '',
        },
        body: formData,
      });

      const data = await response.json();

      if (response.ok) {
        this.#showStatus('Receipt sent! Please check your inbox.', 'success');
        this.emailInputTarget.value = '';
        button.textContent = 'Sent';
        if (consentCheckbox) consentCheckbox.checked = false;
      } else {
        this.#showStatus(data.error || 'Something went wrong. Please try again.', 'error');
        button.disabled = false;
        button.textContent = 'Send';
      }
    } catch (_err) {
      this.#showStatus('Network error. Please try again.', 'error');
      button.disabled = false;
      button.textContent = 'Send';
    }
  }

  // -- private helpers -------------------------------------------------------

  #validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  #showStatus(message, type) {
    if (!this.hasStatusTarget) return;

    const el = this.statusTarget;

    if (type === 'hidden' || !message) {
      el.style.display = 'none';
      el.textContent = '';
      return;
    }

    el.style.display = 'block';
    el.textContent = message;
    el.style.color = type === 'success' ? '#059669' : '#DC2626';
    el.style.fontSize = '13px';
    el.style.marginTop = '6px';
  }
}
