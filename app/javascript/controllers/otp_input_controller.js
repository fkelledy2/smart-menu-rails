import { Controller } from '@hotwired/stimulus';

// Auto-submits the OTP form when 6 digits are entered (TOTP code).
// Backup codes are 10 characters and do not auto-submit.
export default class extends Controller {
  autoSubmit(event) {
    const value = event.target.value.replace(/\s/g, '');
    if (value.length === 6 && /^\d+$/.test(value)) {
      event.target.closest('form').requestSubmit();
    }
  }
}
