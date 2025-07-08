// Helper to safely initialize TomSelect only if not already initialized
export function initTomSelectIfNeeded(selector, options = {}) {
  const el = typeof selector === 'string' ? document.querySelector(selector) : selector;
  if (el && !el.tomselect) {
    new TomSelect(el, options);
  }
}
