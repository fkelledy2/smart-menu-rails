/**
 * MenuSearchController Tests
 *
 * Covers the client-side search/filter on the smartmenu show page.
 * Tests both customer view (.menu-item-card-mobile) and staff view
 * (.menu-item-card) item selectors, section hiding, no-results display,
 * and the clear() action.
 */

import { Application } from '@hotwired/stimulus';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import MenuSearchController from '@controllers/menu_search_controller';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function buildItem({ id, name, description = '', className = 'menu-item-card-mobile' }) {
  return `<div class="${className}" data-name="${name.toLowerCase()}" data-description="${description.toLowerCase()}" data-testid="menu-item-${id}"></div>`;
}

function buildSection({ id, items }) {
  return `
    <div class="padding-top-lg" id="menusection_${id}" data-testid="menu-section-${id}"></div>
    <div class="row"><div class="col-12"><span class="h3">Section ${id}</span></div></div>
    <div class="row menu-layout-card" data-testid="menu-items-row-${id}">
      ${items}
    </div>
  `;
}

function buildDOM({ sections, itemClass = 'menu-item-card-mobile' } = {}) {
  return `
    <div data-controller="menu-search">
      <input data-menu-search-target="input"
             data-action="input->menu-search#filter"
             data-testid="menu-search-input"
             type="text">
      <div data-menu-search-target="container" id="menuContentContainer">
        ${sections}
      </div>
      <div class="menu-search-no-results d-none"
           data-menu-search-target="noResults"
           data-testid="menu-search-no-results">
        No items found
      </div>
    </div>
  `;
}

// Wait for Stimulus to connect controllers after DOM mutation.
function nextTick() {
  return new Promise((r) => setTimeout(r, 0));
}

// Type into the search input and flush the debounce timer.
async function typeQuery(input, value) {
  input.value = value;
  input.dispatchEvent(new Event('input', { bubbles: true }));
  // Advance past the 150 ms debounce
  vi.advanceTimersByTime(200);
  await nextTick();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('MenuSearchController', () => {
  let application;

  beforeEach(async () => {
    vi.useFakeTimers();
    application = Application.start();
    application.register('menu-search', MenuSearchController);
    await nextTick();
  });

  afterEach(() => {
    application.stop();
    vi.useRealTimers();
  });

  // -------------------------------------------------------------------------
  // Customer view — .menu-item-card-mobile
  // -------------------------------------------------------------------------

  describe('customer view (.menu-item-card-mobile)', () => {
    beforeEach(async () => {
      const sections = buildSection({
        id: 1,
        items:
          buildItem({ id: 10, name: 'Eggs Benedict', description: 'hollandaise sauce', className: 'menu-item-card-mobile' }) +
          buildItem({ id: 11, name: 'Pancakes', description: 'maple syrup', className: 'menu-item-card-mobile' }),
      });
      document.body.innerHTML = buildDOM({ sections });
      await nextTick();
    });

    it('shows all items when query is empty', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, '');

      const items = document.querySelectorAll('.menu-item-card-mobile');
      items.forEach((item) => expect(item.classList.contains('search-hidden')).toBe(false));
    });

    it('hides items that do not match the query', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'pancake');

      const benedict = document.querySelector('[data-testid="menu-item-10"]');
      const pancakes = document.querySelector('[data-testid="menu-item-11"]');

      expect(benedict.classList.contains('search-hidden')).toBe(true);
      expect(pancakes.classList.contains('search-hidden')).toBe(false);
    });

    it('matches on description as well as name', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'hollandaise');

      const benedict = document.querySelector('[data-testid="menu-item-10"]');
      const pancakes = document.querySelector('[data-testid="menu-item-11"]');

      expect(benedict.classList.contains('search-hidden')).toBe(false);
      expect(pancakes.classList.contains('search-hidden')).toBe(true);
    });

    it('is case-insensitive', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'EGGS');

      const benedict = document.querySelector('[data-testid="menu-item-10"]');
      expect(benedict.classList.contains('search-hidden')).toBe(false);
    });

    it('shows no-results message when nothing matches', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'xyzzy');

      const noResults = document.querySelector('[data-testid="menu-search-no-results"]');
      expect(noResults.classList.contains('d-none')).toBe(false);
    });

    it('hides no-results message when there are matches', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'eggs');

      const noResults = document.querySelector('[data-testid="menu-search-no-results"]');
      expect(noResults.classList.contains('d-none')).toBe(true);
    });

    it('hides no-results message when query is cleared', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'xyzzy');
      await typeQuery(input, '');

      const noResults = document.querySelector('[data-testid="menu-search-no-results"]');
      expect(noResults.classList.contains('d-none')).toBe(true);
    });
  });

  // -------------------------------------------------------------------------
  // Staff view — .menu-item-card  (the bug: this was previously untested and broken)
  // -------------------------------------------------------------------------

  describe('staff view (.menu-item-card)', () => {
    beforeEach(async () => {
      const sections = buildSection({
        id: 2,
        items:
          buildItem({ id: 20, name: 'Grilled Salmon', description: 'lemon butter', className: 'menu-item-card' }) +
          buildItem({ id: 21, name: 'Caesar Salad', description: 'anchovies croutons', className: 'menu-item-card' }),
      });
      document.body.innerHTML = buildDOM({ sections });
      await nextTick();
    });

    it('hides staff items that do not match the query', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'salmon');

      const salmon = document.querySelector('[data-testid="menu-item-20"]');
      const caesar = document.querySelector('[data-testid="menu-item-21"]');

      expect(salmon.classList.contains('search-hidden')).toBe(false);
      expect(caesar.classList.contains('search-hidden')).toBe(true);
    });

    it('matches staff items by description', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'anchovies');

      const salmon = document.querySelector('[data-testid="menu-item-20"]');
      const caesar = document.querySelector('[data-testid="menu-item-21"]');

      expect(salmon.classList.contains('search-hidden')).toBe(true);
      expect(caesar.classList.contains('search-hidden')).toBe(false);
    });

    it('shows all staff items when query is cleared', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'salmon');
      await typeQuery(input, '');

      document.querySelectorAll('.menu-item-card').forEach((item) => {
        expect(item.classList.contains('search-hidden')).toBe(false);
      });
    });

    it('shows no-results when no staff items match', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'xyzzy');

      const noResults = document.querySelector('[data-testid="menu-search-no-results"]');
      expect(noResults.classList.contains('d-none')).toBe(false);
    });
  });

  // -------------------------------------------------------------------------
  // Section hiding — hidden when all items in that section are filtered out
  // -------------------------------------------------------------------------

  describe('section hiding', () => {
    beforeEach(async () => {
      const sections =
        buildSection({
          id: 1,
          items: buildItem({ id: 10, name: 'Waffles', className: 'menu-item-card-mobile' }),
        }) +
        buildSection({
          id: 2,
          items: buildItem({ id: 20, name: 'Burger', className: 'menu-item-card-mobile' }),
        });
      document.body.innerHTML = buildDOM({ sections });
      await nextTick();
    });

    it('hides the section anchor and header when all items are filtered', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'waffle');

      const sec1Anchor = document.getElementById('menusection_1');
      const sec2Anchor = document.getElementById('menusection_2');
      const sec2Row = document.querySelector('[data-testid="menu-items-row-2"]');

      expect(sec1Anchor.classList.contains('search-hidden')).toBe(false);
      expect(sec2Anchor.classList.contains('search-hidden')).toBe(true);
      expect(sec2Row.classList.contains('search-section-hidden')).toBe(true);
    });

    it('reveals hidden sections when query is cleared', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'waffle');
      await typeQuery(input, '');

      const sec2Anchor = document.getElementById('menusection_2');
      const sec2Row = document.querySelector('[data-testid="menu-items-row-2"]');

      expect(sec2Anchor.classList.contains('search-hidden')).toBe(false);
      expect(sec2Row.classList.contains('search-section-hidden')).toBe(false);
    });

    it('hides sections correctly for staff view items', async () => {
      // Rebuild with staff-class items
      const sections =
        buildSection({ id: 3, items: buildItem({ id: 30, name: 'Steak', className: 'menu-item-card' }) }) +
        buildSection({ id: 4, items: buildItem({ id: 40, name: 'Pasta', className: 'menu-item-card' }) });
      document.body.innerHTML = buildDOM({ sections });
      await nextTick();

      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'steak');

      const sec3Anchor = document.getElementById('menusection_3');
      const sec4Anchor = document.getElementById('menusection_4');
      const sec4Row = document.querySelector('[data-testid="menu-items-row-4"]');

      expect(sec3Anchor.classList.contains('search-hidden')).toBe(false);
      expect(sec4Anchor.classList.contains('search-hidden')).toBe(true);
      expect(sec4Row.classList.contains('search-section-hidden')).toBe(true);
    });
  });

  // -------------------------------------------------------------------------
  // clear() action
  // -------------------------------------------------------------------------

  describe('clear()', () => {
    beforeEach(async () => {
      const sections = buildSection({
        id: 1,
        items: buildItem({ id: 10, name: 'Croissant', className: 'menu-item-card-mobile' }),
      });
      document.body.innerHTML = buildDOM({ sections });
      await nextTick();
    });

    it('resets the input and shows all items', async () => {
      const input = document.querySelector('[data-testid="menu-search-input"]');
      await typeQuery(input, 'xyzzy');

      // Call clear() directly on the controller instance
      const controllerEl = document.querySelector('[data-controller="menu-search"]');
      const controller = application.getControllerForElementAndIdentifier(controllerEl, 'menu-search');
      controller.clear();
      vi.advanceTimersByTime(0);
      await nextTick();

      expect(input.value).toBe('');
      const item = document.querySelector('[data-testid="menu-item-10"]');
      expect(item.classList.contains('search-hidden')).toBe(false);
    });
  });
});
