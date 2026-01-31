import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['password', 'confirmationWrapper', 'confirmation'];

  connect() {
    this.toggle();
  }

  toggle() {
    const hasPassword = (this.passwordTarget.value || '').trim().length > 0;

    this.confirmationWrapperTarget.classList.toggle('d-none', !hasPassword);
    this.confirmationTarget.disabled = !hasPassword;

    if (!hasPassword) {
      this.confirmationTarget.value = '';
    }
  }
}
