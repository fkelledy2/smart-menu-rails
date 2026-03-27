import { Controller } from '@hotwired/stimulus';

/**
 * CRM Lead Detail Controller
 *
 * Manages the Convert modal trigger on the lead show page.
 * Tab switching is handled by Bootstrap's built-in data-bs-toggle="tab".
 */
export default class extends Controller {
  connect() {
    // Bootstrap tabs are handled natively via data-bs-toggle.
    // This controller handles the convert modal.
  }

  openConvertModal(event) {
    event.preventDefault();
    const modal = document.getElementById('convertModal');
    if (modal && window.bootstrap?.Modal) {
      const bsModal = new window.bootstrap.Modal(modal);
      bsModal.show();
    } else if (modal) {
      // Fallback: show via class manipulation if Bootstrap JS not loaded
      modal.style.display = 'block';
      modal.classList.add('show');
    }
  }
}
