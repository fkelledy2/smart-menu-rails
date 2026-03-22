import { Controller } from '@hotwired/stimulus';

// Auto-shows a Bootstrap modal once per session (keyed by data-welcome-modal-key-value).
// Auto-dismisses after 3 seconds.
export default class extends Controller {
  static values = { key: String };

  connect() {
    if (sessionStorage.getItem(this.keyValue)) return;
    this._show();
  }

  _show() {
    if (!window.bootstrap) return;
    sessionStorage.setItem(this.keyValue, '1');
    const modal = new window.bootstrap.Modal(this.element, { backdrop: true, keyboard: true });
    modal.show();
    setTimeout(() => modal.hide(), 3000);
  }
}
