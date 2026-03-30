import { Controller } from '@hotwired/stimulus';

// Auto-shows a Bootstrap modal once per session (keyed by data-welcome-modal-key-value).
// Auto-dismisses after 3 seconds.
export default class extends Controller {
  static values = { key: String };

  connect() {
    this._hideTimer = null;
    if (sessionStorage.getItem(this.keyValue)) return;
    this._show();
  }

  disconnect() {
    if (this._hideTimer) {
      clearTimeout(this._hideTimer);
      this._hideTimer = null;
    }
  }

  _show() {
    if (!window.bootstrap) return;
    sessionStorage.setItem(this.keyValue, '1');
    const modal = window.bootstrap.Modal.getOrCreateInstance(this.element, { backdrop: true, keyboard: true });
    modal.show();
    this._hideTimer = setTimeout(() => modal.hide(), 3000);
  }
}
