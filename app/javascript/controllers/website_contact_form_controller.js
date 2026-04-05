import { Controller } from '@hotwired/stimulus'

// Handles inline validation and submit-state management for the public
// website contact form. No honeypot manipulation here — that's server-side.
export default class extends Controller {
  static targets = ['submitButton']

  connect () {
    this.element.addEventListener('submit', this.handleSubmit.bind(this))
  }

  disconnect () {
    this.element.removeEventListener('submit', this.handleSubmit.bind(this))
  }

  handleSubmit (event) {
    if (!this.element.checkValidity()) {
      event.preventDefault()
      event.stopPropagation()
      this.element.classList.add('was-validated')
      return
    }

    // Disable the submit button to prevent double-submission
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Sending…'
    }
  }
}
