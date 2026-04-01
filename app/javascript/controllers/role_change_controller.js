// role_change_controller.js
// Manages opening/closing the inline Change Role form for an employee row.
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { employeeId: Number };

  // Opens the change-role form by replacing the modal placeholder via Turbo.
  // The form partial is fetched from the server and injected.
  open(event) {
    event.preventDefault();
    const employeeId = event.params?.employeeId || this.employeeIdValue;

    // The form is rendered inside the staff section via a separate fetch.
    // We trigger a Turbo Frame load by setting the src of a hidden frame.
    const frame = document.getElementById(`change_role_form_frame_${employeeId}`);
    if (frame) {
      frame.removeAttribute('src'); // reset to allow reload
      frame.setAttribute('src', event.currentTarget.dataset.src || '');
    }
  }

  // Collapses the inline form by replacing the modal target with empty content.
  close(event) {
    event.preventDefault();
    const employeeId = event.params?.employeeId || this.employeeIdValue;
    const modal = document.getElementById(`change_role_modal_${employeeId}`);
    if (modal) {
      modal.remove();
    }
    // Also clear the Turbo Frame so re-opening works cleanly.
    const frame = document.getElementById(`change_role_form_frame_${employeeId}`);
    if (frame) {
      frame.innerHTML = '';
      frame.removeAttribute('src');
    }
  }
}
