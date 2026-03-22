import { Controller } from '@hotwired/stimulus';

// Theme toggle controller — cycles through light / dark / auto (system).
// Persists choice in localStorage under "theme" key.
// Sets data-theme on <html> so CSS picks it up instantly.
export default class extends Controller {
  static targets = ['icon'];

  connect() {
    this._applyStoredTheme();
  }

  toggle() {
    const current = this._currentTheme();
    let next;
    if (current === 'light') {
      next = 'dark';
    } else if (current === 'dark') {
      next = 'auto';
    } else {
      next = 'light';
    }
    this._setTheme(next);
  }

  // Allow setting a specific theme from a dropdown
  setLight() {
    this._setTheme('light');
  }
  setDark() {
    this._setTheme('dark');
  }
  setAuto() {
    this._setTheme('auto');
  }

  // --- Private ---

  _currentTheme() {
    return localStorage.getItem('theme') || 'auto';
  }

  _setTheme(theme) {
    if (theme === 'auto') {
      localStorage.removeItem('theme');
      document.documentElement.removeAttribute('data-theme');
    } else {
      localStorage.setItem('theme', theme);
      document.documentElement.setAttribute('data-theme', theme);
    }
    this._updateIcon(theme);
  }

  _applyStoredTheme() {
    const stored = localStorage.getItem('theme');
    if (stored && (stored === 'light' || stored === 'dark')) {
      document.documentElement.setAttribute('data-theme', stored);
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
    this._updateIcon(stored || 'auto');
  }

  _updateIcon(theme) {
    if (!this.hasIconTarget) return;
    const icons = { light: 'bi-sun-fill', dark: 'bi-moon-fill', auto: 'bi-circle-half' };
    const titles = { light: 'Light mode', dark: 'Dark mode', auto: 'System theme' };
    this.iconTarget.className = `bi ${icons[theme] || icons.auto}`;
    this.element.setAttribute('title', titles[theme] || titles.auto);
  }
}
