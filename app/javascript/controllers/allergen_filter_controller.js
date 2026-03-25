import { Controller } from '@hotwired/stimulus';

// Manages allergen filter selection in the allergen modal.
// Persists selection to localStorage and hides/shows menu item cards accordingly.
export default class extends Controller {
  static targets = ['row', 'count', 'clearBtn'];
  static values = { storageKey: { type: String, default: 'sm_allergen_filters' } };

  connect() {
    this.selected = new Set();
    this._restore();
    this._renderRows();
    this._applyFilter();
  }

  toggle(event) {
    event.preventDefault();
    const code = event.currentTarget.dataset.allergenCode;
    if (this.selected.has(code)) {
      this.selected.delete(code);
    } else {
      this.selected.add(code);
    }
    this._save();
    this._renderRows();
    this._applyFilter();
  }

  clearAll() {
    this.selected.clear();
    this._save();
    this._renderRows();
    this._applyFilter();
  }

  _restore() {
    try {
      const saved = JSON.parse(localStorage.getItem(this.storageKeyValue));
      if (Array.isArray(saved)) saved.forEach((c) => this.selected.add(c));
    } catch (_) {}
  }

  _save() {
    try {
      localStorage.setItem(this.storageKeyValue, JSON.stringify([...this.selected]));
    } catch (_) {}
  }

  _renderRows() {
    this.rowTargets.forEach((row) => {
      const code = row.dataset.allergenCode;
      const icon = row.querySelector('.allergen-check-icon');
      const isOn = this.selected.has(code);
      if (icon) icon.style.display = isOn ? '' : 'none';
      row.classList.toggle('active', isOn);
    });
    const n = this.selected.size;
    if (this.hasCountTarget) {
      this.countTarget.textContent = n > 0 ? `${n} selected` : '';
    }
    if (this.hasClearBtnTarget) {
      this.clearBtnTarget.style.display = n > 0 ? '' : 'none';
    }
  }

  _applyFilter() {
    document.querySelectorAll('.menu-item-card-mobile').forEach((card) => {
      if (this.selected.size === 0) {
        card.style.display = '';
        return;
      }
      const badges = card.querySelectorAll('.allergen-badges .badge.bg-warning');
      const cardAllergens = [...badges].map((b) => b.textContent.trim());
      card.style.display = cardAllergens.some((c) => this.selected.has(c)) ? 'none' : '';
    });
    const triggerBadge = document.querySelector('[data-bs-target="#allergenModal"] .filter-badge');
    if (triggerBadge) {
      triggerBadge.textContent = this.selected.size;
      triggerBadge.style.display = this.selected.size > 0 ? '' : 'none';
    }
  }
}
