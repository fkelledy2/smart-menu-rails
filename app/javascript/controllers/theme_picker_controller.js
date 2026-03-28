import { Controller } from '@hotwired/stimulus';

// Theme picker controller — manages the restaurant theme selector on the
// smartmenu edit page. Updates the hidden theme input and manages swatch
// active state. A "Preview" button opens the public smartmenu URL in a new tab.
export default class extends Controller {
  static targets = ['swatch', 'input', 'previewLink'];

  connect() {
    this._updateActiveState(this.inputTarget.value);
  }

  selectTheme(event) {
    const swatch = event.currentTarget;
    const value = swatch.dataset.themeValue;
    if (!value) return;

    this.inputTarget.value = value;
    this._updateActiveState(value);
    this._updatePreviewLink(value);

    // Auto-submit if this picker lives inside a standalone form (restaurant dashboard)
    const form = this.element.closest('form');
    if (form) form.requestSubmit();
  }

  // --- Private ---

  _updateActiveState(activeValue) {
    this.swatchTargets.forEach((swatch) => {
      swatch.classList.toggle('theme-swatch--active', swatch.dataset.themeValue === activeValue);
    });
  }

  _updatePreviewLink(themeValue) {
    if (!this.hasPreviewLinkTarget) return;
    const url = new URL(this.previewLinkTarget.href);
    url.searchParams.set('theme_preview', themeValue);
    this.previewLinkTarget.href = url.toString();
  }
}
