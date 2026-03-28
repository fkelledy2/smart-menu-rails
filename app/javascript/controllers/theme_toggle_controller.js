import { Controller } from '@hotwired/stimulus';

// Theme toggle controller — cycles through light / dark / auto (system).
// Persists choice in localStorage under "colorScheme" key.
// Sets data-color-scheme on <html> so CSS picks it up instantly.
// NOTE: data-color-scheme (light/dark) is orthogonal to data-theme (modern/rustic/elegant).
export default class extends Controller {
  static targets = ['icon'];

  connect() {
    this._applyStoredScheme();
  }

  toggle() {
    const current = this._currentScheme();
    let next;
    if (current === 'light') {
      next = 'dark';
    } else if (current === 'dark') {
      next = 'auto';
    } else {
      next = 'light';
    }
    this._setScheme(next);
  }

  // Allow setting a specific colour scheme from a dropdown
  setLight() {
    this._setScheme('light');
  }
  setDark() {
    this._setScheme('dark');
  }
  setAuto() {
    this._setScheme('auto');
  }

  // --- Private ---

  _currentScheme() {
    return localStorage.getItem('colorScheme') || 'auto';
  }

  _setScheme(scheme) {
    if (scheme === 'auto') {
      localStorage.removeItem('colorScheme');
      document.documentElement.removeAttribute('data-color-scheme');
    } else {
      localStorage.setItem('colorScheme', scheme);
      document.documentElement.setAttribute('data-color-scheme', scheme);
    }
    this._updateIcon(scheme);
  }

  _applyStoredScheme() {
    const stored = localStorage.getItem('colorScheme');
    if (stored && (stored === 'light' || stored === 'dark')) {
      document.documentElement.setAttribute('data-color-scheme', stored);
    } else {
      document.documentElement.removeAttribute('data-color-scheme');
    }
    this._updateIcon(stored || 'auto');
  }

  _updateIcon(scheme) {
    if (!this.hasIconTarget) return;
    const icons = { light: 'bi-sun-fill', dark: 'bi-moon-fill', auto: 'bi-circle-half' };
    const titles = { light: 'Light mode', dark: 'Dark mode', auto: 'System theme' };
    this.iconTarget.className = `bi ${icons[scheme] || icons.auto}`;
    this.element.setAttribute('title', titles[scheme] || titles.auto);
  }
}
