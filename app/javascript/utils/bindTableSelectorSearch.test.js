import { describe, it, expect, beforeEach } from 'vitest';
import { bindTableSelectorSearch } from './bindTableSelectorSearch';

function buildMenu(itemsCount = 10) {
  document.body.innerHTML = `
    <ul class="dropdown-menu table-dropdown-menu">
      <li class="dropdown-search"><div><input id="table-selector-search" type="text" /></div></li>
      ${Array.from({ length: itemsCount }).map((_, i) => `
        <li><a class="dropdown-item" data-filter-text="Table ${i+1}">Table ${i+1}</a></li>
      `).join('')}
    </ul>
  `;
}

describe('bindTableSelectorSearch', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('binds once (idempotent)', () => {
    buildMenu(5);
    const first = bindTableSelectorSearch();
    const second = bindTableSelectorSearch();
    expect(first).toBe(true);
    expect(second).toBe(true); // returns true even if already bound
  });

  it('filters items by query (case-insensitive)', async () => {
    buildMenu(5);
    bindTableSelectorSearch({ debounceMs: 0 });
    const input = document.getElementById('table-selector-search');
    input.value = 'table 3';
    input.dispatchEvent(new Event('input'));

    const lis = Array.from(document.querySelectorAll('.table-dropdown-menu li'));
    // Skip the first li (search row)
    const rows = lis.slice(1);
    const visibleTexts = rows
      .filter(li => li.style.display !== 'none')
      .map(li => li.textContent.trim());

    expect(visibleTexts).toEqual(['Table 3']);
  });

  it('shows all items when query cleared', async () => {
    buildMenu(5);
    bindTableSelectorSearch({ debounceMs: 0 });
    const input = document.getElementById('table-selector-search');

    input.value = 'table 1';
    input.dispatchEvent(new Event('input'));

    input.value = '';
    input.dispatchEvent(new Event('input'));

    const lis = Array.from(document.querySelectorAll('.table-dropdown-menu li'));
    const rows = lis.slice(1);
    const visibleCount = rows.filter(li => li.style.display !== 'none').length;
    expect(visibleCount).toBe(5);
  });

  it('handles large lists efficiently (basic performance smoke)', () => {
    const N = 1000;
    buildMenu(N);
    const bound = bindTableSelectorSearch({ debounceMs: 0 });
    expect(bound).toBe(true);

    const input = document.getElementById('table-selector-search');
    const t0 = performance.now();
    input.value = '999';
    input.dispatchEvent(new Event('input'));
    const t1 = performance.now();

    // Simple smoke threshold: filtering 1000 items should be well under 50ms on CI
    expect(t1 - t0).toBeLessThan(50);

    const visible = Array.from(document.querySelectorAll('.table-dropdown-menu li'))
      .slice(1)
      .filter(li => li.style.display !== 'none');
    expect(visible.length).toBeGreaterThanOrEqual(1);
  });
});
