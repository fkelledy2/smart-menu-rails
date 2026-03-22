import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'count'];

  connect() {
    this._update();
  }

  update() {
    this._update();
  }

  _update() {
    if (this.hasInputTarget && this.hasCountTarget) {
      this.countTarget.textContent = this.inputTarget.value.length;
    }
  }
}
