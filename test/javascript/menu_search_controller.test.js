/**
 * MenuSearchController Tests
 *
 * Covers the client-side search/filter on the smartmenu show page.
 * Tests both customer view (.menu-item-card-mobile) and staff view
 * (.menu-item-card) item selectors, section hiding, no-results display,
 * and the clear() action.
 *
 * Key regression: staff-view items use .menu-item-card (no -mobile suffix).
 * Before the fix the controller only queried .menu-item-card-mobile so search
 * produced zero results in staff mode.
 */

import { Application } from '@hotwired/stimulus';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import MenuSearchController from '@controllers/menu_search_controller';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Build a single menu item div with data-name / data-description attributes.
 * className controls which view is simulated:
 *   'menu-item-card-mobile' → customer view
 *   'menu-item-card'        → staff view  (the previously broken case)
 */
function buildItem({ id, name, description = '', className = 'menu-item-card-mobile' }) {
  return `<div class="${className}"
               data-name="${name.toLowerCase()}"
               data-description="${description.toLowerCase()}"
               data-testid="menu-item-${id}"></div>`;
}

/**
 * Build a section with the anchor div, header row, and items row structure
 * that _menu_section.html.erb produces.
 */
function buildSection({ id, items }) {
  return `
    <div class="padding-top-lg" id="menusection_${id}" data-testid="menu-section-${id}"></div>
    <div class="row"><div class="col-12"><span class="h3">Section ${id}</span></div></div>
    <div class="row menu-layout-card" data-testid="menu-items-row-${id}">
      ${items}
    </div>`;
}

/**
 * Wrap sections in the full controller scaffold.
 * debounce="0" makes filtering synchronous so tests don't need fake timers.
 */
function buildDOM(sections) {
  return `
    <div data-controller="menu-search" data-menu-search-debounce-value="0">
      <input data-menu-search-target="input"
             data-action="input->menu-search#filter"
             data-testid="menu-search-input"
             type="text">
      <div data-menu-search-target="container" id="menuContentContainer">
        ${sections}
      </div>
      <div class="menu-search-no-results d-none"
           data-menu-search-target="noResults"
           data-testid="menu-search-no-results">No items found</div>
    </div>`;
}

/**
 * Dispatch an input event on the search field and wait for Stimulus to
 * process it (two microtask/task cycles covers the 0 ms debounce + filter).
 */
async function search(query) {
  const input = document.querySelector('[data-testid="menu-search-input"]');
  input.value = query;
  input.dispatchEvent(new Event('input', { bubbles: true }));
  // Flush the 0 ms debounce setTimeout and the filter pass
  await new Promise((r) => setTimeout(r, 10));
}

// ---------------------------------------------------------------------------
// Suite
// ---------------------------------------------------------------------------

describe('MenuSearchController', () => {
  let application;

  beforeEach(async () => {
    application = Application.start();
    application.register('menu-search', MenuSearchController);
    // Let Stimulus finish its initial DOM scan
    await new Promise((r) => setTimeout(r, 10));
  });

  afterEach(() => {
    application.stop();
  });

  // =========================================================================
  // Customer view — .menu-item-card-mobile
  // =========================================================================

  describe('customer view (.menu-item-card-mobile)', () => {
    beforeEach(async () => {
      document.body.innerHTML = buildDOM(
        buildSection({
          id: 1,
          items:
            buildItem({ id: 10, name: 'Eggs Benedict', description: 'hollandaise sauce' }) +
            buildItem({ id: 11, name: 'Pancakes', description: 'maple syrup' }),
        }),
      );
      await new Promise((r) => setTimeout(r, 20));
    });

    it('shows all items when query is empty', async () => {
      await search('');
      document.querySelectorAll('.menu-item-card-mobile').forEach((item) => {
        expect(item.classList.contains('search-hidden')).toBe(false);
      });
    });

    it('hides items that do not match the query', async () => {
      await search('pancake');
      expect(document.querySelector('[data-testid="menu-item-10"]').classList.contains('search-hidden')).toBe(true);
      expect(document.querySelector('[data-testid="menu-item-11"]').classList.contains('search-hidden')).toBe(false);
    });

    it('matches on description as well as name', async () => {
      await search('hollandaise');
      expect(document.querySelector('[data-testid="menu-item-10"]').classList.contains('search-hidden')).toBe(false);
      expect(document.querySelector('[data-testid="menu-item-11"]').classList.contains('search-hidden')).toBe(true);
    });

    it('is case-insensitive', async () => {
      await search('EGGS');
      expect(document.querySelector('[data-testid="menu-item-10"]').classList.contains('search-hidden')).toBe(false);
    });

    it('shows no-results message when nothing matches', async () => {
      await search('xyzzy');
      expect(document.querySelector('[data-testid="menu-search-no-results"]').classList.contains('d-none')).toBe(false);
    });

    it('hides no-results message when there are matches', async () => {
      await search('eggs');
      expect(document.querySelector('[data-testid="menu-search-no-results"]').classList.contains('d-none')).toBe(true);
    });

    it('hides no-results message when query is cleared', async () => {
      await search('xyzzy');
      await search('');
      expect(document.querySelector('[data-testid="menu-search-no-results"]').classList.contains('d-none')).toBe(true);
    });

    it('restores all items after clearing a query', async () => {
      await search('pancake');
      await search('');
      document.querySelectorAll('.menu-item-card-mobile').forEach((item) => {
        expect(item.classList.contains('search-hidden')).toBe(false);
      });
    });
  });

  // =========================================================================
  // Staff view — .menu-item-card  (regression: was completely broken before fix)
  // =========================================================================

  describe('staff view (.menu-item-card) — regression for missing selector', () => {
    beforeEach(async () => {
      document.body.innerHTML = buildDOM(
        buildSection({
          id: 2,
          items:
            buildItem({ id: 20, name: 'Grilled Salmon', description: 'lemon butter', className: 'menu-item-card' }) +
            buildItem({ id: 21, name: 'Caesar Salad', description: 'anchovies croutons', className: 'menu-item-card' }),
        }),
      );
      await new Promise((r) => setTimeout(r, 20));
    });

    it('hides staff items that do not match', async () => {
      await search('salmon');
      expect(document.querySelector('[data-testid="menu-item-20"]').classList.contains('search-hidden')).toBe(false);
      expect(document.querySelector('[data-testid="menu-item-21"]').classList.contains('search-hidden')).toBe(true);
    });

    it('matches staff items by description', async () => {
      await search('anchovies');
      expect(document.querySelector('[data-testid="menu-item-20"]').classList.contains('search-hidden')).toBe(true);
      expect(document.querySelector('[data-testid="menu-item-21"]').classList.contains('search-hidden')).toBe(false);
    });

    it('shows all staff items when query is cleared', async () => {
      await search('salmon');
      await search('');
      document.querySelectorAll('.menu-item-card').forEach((item) => {
        expect(item.classList.contains('search-hidden')).toBe(false);
      });
    });

    it('shows no-results when no staff items match', async () => {
      await search('xyzzy');
      expect(document.querySelector('[data-testid="menu-search-no-results"]').classList.contains('d-none')).toBe(false);
    });

    it('is case-insensitive for staff items', async () => {
      await search('GRILLED');
      expect(document.querySelector('[data-testid="menu-item-20"]').classList.contains('search-hidden')).toBe(false);
    });
  });

  // =========================================================================
  // Section hiding
  // =========================================================================

  describe('section hiding', () => {
    it('hides section anchor and header when all customer items are filtered out', async () => {
      document.body.innerHTML = buildDOM(
        buildSection({ id: 1, items: buildItem({ id: 10, name: 'Waffles' }) }) +
        buildSection({ id: 2, items: buildItem({ id: 20, name: 'Burger' }) }),
      );
      await new Promise((r) => setTimeout(r, 20));

      await search('waffle');

      expect(document.getElementById('menusection_1').classList.contains('search-hidden')).toBe(false);
      expect(document.getElementById('menusection_2').classList.contains('search-hidden')).toBe(true);
      expect(document.querySelector('[data-testid="menu-items-row-2"]').classList.contains('search-section-hidden')).toBe(true);
    });

    it('reveals hidden sections when query is cleared', async () => {
      document.body.innerHTML = buildDOM(
        buildSection({ id: 1, items: buildItem({ id: 10, name: 'Waffles' }) }) +
        buildSection({ id: 2, items: buildItem({ id: 20, name: 'Burger' }) }),
      );
      await new Promise((r) => setTimeout(r, 20));

      await search('waffle');
      await search('');

      expect(document.getElementById('menusection_2').classList.contains('search-hidden')).toBe(false);
      expect(document.querySelector('[data-testid="menu-items-row-2"]').classList.contains('search-section-hidden')).toBe(false);
    });

    it('hides sections correctly for staff-view items — regression', async () => {
      document.body.innerHTML = buildDOM(
        buildSection({ id: 3, items: buildItem({ id: 30, name: 'Steak', className: 'menu-item-card' }) }) +
        buildSection({ id: 4, items: buildItem({ id: 40, name: 'Pasta', className: 'menu-item-card' }) }),
      );
      await new Promise((r) => setTimeout(r, 20));

      await search('steak');

      expect(document.getElementById('menusection_3').classList.contains('search-hidden')).toBe(false);
      expect(document.getElementById('menusection_4').classList.contains('search-hidden')).toBe(true);
      expect(document.querySelector('[data-testid="menu-items-row-4"]').classList.contains('search-section-hidden')).toBe(true);
    });
  });

  // =========================================================================
  // clear() action
  // =========================================================================

  describe('clear()', () => {
    beforeEach(async () => {
      document.body.innerHTML = buildDOM(
        buildSection({ id: 1, items: buildItem({ id: 10, name: 'Croissant' }) }),
      );
      await new Promise((r) => setTimeout(r, 20));
    });

    it('resets the input value and shows all items', async () => {
      await search('xyzzy');

      const controllerEl = document.querySelector('[data-controller="menu-search"]');
      const controller = application.getControllerForElementAndIdentifier(controllerEl, 'menu-search');
      controller.clear();
      await new Promise((r) => setTimeout(r, 10));

      expect(document.querySelector('[data-testid="menu-search-input"]').value).toBe('');
      expect(document.querySelector('[data-testid="menu-item-10"]').classList.contains('search-hidden')).toBe(false);
    });
  });
});
