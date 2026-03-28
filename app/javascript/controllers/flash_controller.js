import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this._showAll();
    this._observe();
  }

  disconnect() {
    this._observer?.disconnect();
  }

  _showAll() {
    this.element.querySelectorAll('.toast:not(.showed)').forEach((el) => {
      el.classList.add('showed');
      new bootstrap.Toast(el, { autohide: true, delay: 4000 }).show();
    });
  }

  _observe() {
    this._observer = new MutationObserver(() => this._showAll());
    this._observer.observe(this.element, { childList: true, subtree: true });
  }
}
