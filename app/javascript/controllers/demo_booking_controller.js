import { Controller } from '@hotwired/stimulus';

// Handles the demo booking modal form.
// Submits via fetch (JSON), then transitions to the Calendly success step.
export default class extends Controller {
  static targets = [
    'formStep',
    'successStep',
    'errorBox',
    'submitBtn',
    'contactName',
    'restaurantName',
    'email',
    'phone',
    'restaurantType',
    'locationCount',
    'interests',
    'calendlyContainer',
    'calendlyLink',
  ];

  static values = {
    url: String, // /demo_bookings
    csrf: String, // form authenticity token
  };

  async submit(event) {
    event.preventDefault();

    if (!this.#validate()) return;

    this.submitBtnTarget.disabled = true;
    this.submitBtnTarget.textContent = 'Sending…';
    this.#hideErrors();

    const payload = {
      demo_booking: {
        contact_name: this.contactNameTarget.value.trim(),
        restaurant_name: this.restaurantNameTarget.value.trim(),
        email: this.emailTarget.value.trim(),
        phone: this.phoneTarget.value.trim(),
        restaurant_type: this.restaurantTypeTarget.value,
        location_count: this.locationCountTarget.value,
        interests: this.interestsTarget.value.trim(),
      },
    };

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': this.csrfValue,
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (response.ok && data.ok) {
        this.#showSuccess(data.calendly_url);
      } else {
        const messages = data.errors || ['Something went wrong. Please try again.'];
        this.#showErrors(messages);
        this.submitBtnTarget.disabled = false;
        this.submitBtnTarget.textContent = 'Book my demo →';
      }
    } catch (_err) {
      this.#showErrors(['Network error. Please check your connection and try again.']);
      this.submitBtnTarget.disabled = false;
      this.submitBtnTarget.textContent = 'Book my demo →';
    }
  }

  // -- private helpers --------------------------------------------------------

  #validate() {
    const errors = [];

    if (!this.contactNameTarget.value.trim()) {
      errors.push('Your name is required.');
    }
    if (!this.restaurantNameTarget.value.trim()) {
      errors.push('Restaurant name is required.');
    }
    if (!this.#validEmail(this.emailTarget.value.trim())) {
      errors.push('A valid email address is required.');
    }

    if (errors.length > 0) {
      this.#showErrors(errors);
      return false;
    }
    return true;
  }

  #validEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  #showErrors(messages) {
    if (!this.hasErrorBoxTarget) return;
    this.errorBoxTarget.innerHTML = messages.map((m) => `<div>${m}</div>`).join('');
    this.errorBoxTarget.classList.remove('d-none');
  }

  #hideErrors() {
    if (!this.hasErrorBoxTarget) return;
    this.errorBoxTarget.classList.add('d-none');
    this.errorBoxTarget.innerHTML = '';
  }

  #showSuccess(calendlyUrl) {
    // Show a brief inline confirmation message, then close the modal after 2 s
    // and redirect to the success step with the Calendly widget.
    this.formStepTarget.innerHTML = `
      <div class="modal-body text-center py-5">
        <i class="bi bi-check-circle-fill text-success" style="font-size: 3rem;"></i>
        <h4 class="mt-3 fw-bold">Thanks! We'll be in touch shortly.</h4>
        <p class="text-muted mb-0">Check your inbox for a confirmation email.</p>
      </div>
    `;

    setTimeout(() => {
      // Close the modal using Bootstrap's API
      const modalEl = this.element.closest('.modal');
      if (modalEl) {
        const bsModal = window.bootstrap && window.bootstrap.Modal.getInstance(modalEl);
        if (bsModal) {
          bsModal.hide();
        }
      }

      // After closing, swap to the Calendly step in case the user re-opens the page.
      this.formStepTarget.classList.add('d-none');
      this.successStepTarget.classList.remove('d-none');

      // Update the Calendly fallback link
      if (this.hasCalendlyLinkTarget && calendlyUrl) {
        this.calendlyLinkTarget.href = calendlyUrl;
      }

      // Attempt to load the Calendly inline widget if the script is available.
      // This is a progressive enhancement — if Calendly's script is not loaded,
      // we fall back to the direct link shown in the container.
      if (window.Calendly && calendlyUrl && this.hasCalendlyContainerTarget) {
        this.calendlyContainerTarget.innerHTML = '';
        window.Calendly.initInlineWidget({
          url: calendlyUrl,
          parentElement: this.calendlyContainerTarget,
          prefill: {},
          utm: {},
        });
      }
    }, 2000);
  }
}
