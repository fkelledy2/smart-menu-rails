// role_change_form_controller.js
// Handles demotion warning display and submit button state inside the Change Role form.
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['roleSelect', 'demotionWarning', 'demotionConfirm', 'submitBtn'];
  static values = { isDemotion: Boolean };

  connect() {
    this.syncSubmit();
  }

  // Called when the role select changes. Shows the demotion warning if needed.
  checkDemotion() {
    const select = this.roleSelectTarget;
    const selectedRole = select.value;
    const currentRole = select.dataset.currentRole;

    const roleOrder = { staff: 0, manager: 1, admin: 2 };
    const isDemotion =
      selectedRole !== '' &&
      currentRole !== '' &&
      (roleOrder[selectedRole] ?? -1) < (roleOrder[currentRole] ?? -1);

    this.isDemotionValue = isDemotion;

    if (this.hasDemotionWarningTarget) {
      this.demotionWarningTarget.classList.toggle('d-none', !isDemotion);
    }

    if (this.hasDemotionConfirmTarget && !isDemotion) {
      this.demotionConfirmTarget.checked = false;
    }

    this.syncSubmit();
  }

  // Enable/disable submit based on demotion confirmation state.
  syncSubmit() {
    if (!this.hasSubmitBtnTarget) return;

    const roleSelected = this.hasRoleSelectTarget && this.roleSelectTarget.value !== '';

    if (!this.isDemotionValue) {
      this.submitBtnTarget.disabled = !roleSelected;
      return;
    }

    const confirmed = this.hasDemotionConfirmTarget && this.demotionConfirmTarget.checked;
    this.submitBtnTarget.disabled = !roleSelected || !confirmed;
  }
}
