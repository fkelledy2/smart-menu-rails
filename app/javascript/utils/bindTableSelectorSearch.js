export function bindTableSelectorSearch({ menuSelector = '.table-dropdown-menu', inputId = 'table-selector-search', debounceMs = 180 } = {}) {
  const menuEl = document.querySelector(menuSelector);
  const input = document.getElementById(inputId);
  if (!menuEl || !input) return false;
  if (input.__bound) return true; // idempotency guard
  input.__bound = true;

  const items = Array.from(menuEl.querySelectorAll('li > a.dropdown-item'));
  const getText = (a) => (a.getAttribute('data-filter-text') || a.textContent || '').toLowerCase();
  const liFromA = (a) => a.closest('li');
  const debounce = (fn, ms) => { let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); }; };

  const applyFilter = (q) => {
    const query = (q || '').trim().toLowerCase();
    if (!query) {
      items.forEach((a) => { const li = liFromA(a); if (li) li.style.display = ''; });
      return;
    }
    items.forEach((a) => {
      const li = liFromA(a);
      if (!li) return;
      const text = getText(a);
      li.style.display = text.includes(query) ? '' : 'none';
    });
  };

  input.addEventListener('input', debounce((e) => applyFilter(e.target.value), debounceMs));
  return true;
}
