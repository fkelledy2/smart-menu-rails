import { Controller } from "@hotwired/stimulus"

/**
 * Menu Search Controller
 * Client-side search/filter for customer-facing smartmenu.
 * Filters menu items by toggling CSS classes (no DOM removal).
 * Debounces input at 150ms.
 *
 * Usage:
 * <div data-controller="menu-search">
 *   <input data-menu-search-target="input" data-action="input->menu-search#filter">
 *   <div data-menu-search-target="container">…sections with .menu-item-card-mobile[data-name]…</div>
 * </div>
 */
export default class extends Controller {
  static targets = ["input", "container", "noResults"]

  static values = {
    debounce: { type: Number, default: 150 }
  }

  connect() {
    this._timer = null
  }

  disconnect() {
    if (this._timer) clearTimeout(this._timer)
  }

  filter() {
    if (this._timer) clearTimeout(this._timer)
    this._timer = setTimeout(() => this._applyFilter(), this.debounceValue)
  }

  clear() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    this._applyFilter()
  }

  _applyFilter() {
    const query = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()
    const container = this.hasContainerTarget ? this.containerTarget : this.element

    // Reveal all lazy-loaded sections so search can find items in them
    if (query) {
      container.querySelectorAll(".lazy-section:not(.lazy-revealed)").forEach(s => {
        s.classList.add("lazy-revealed")
      })
    }

    const items = container.querySelectorAll(".menu-item-card-mobile")
    let totalVisible = 0

    // Toggle item visibility via CSS class
    items.forEach(item => {
      const name = (item.dataset.name || "").toLowerCase()
      const desc = (item.dataset.description || "").toLowerCase()
      const match = !query || name.includes(query) || desc.includes(query)
      item.classList.toggle("search-hidden", !match)
      if (match) totalVisible++
    })

    // Toggle section visibility — hide sections where all items are hidden
    const sections = container.querySelectorAll("[id^='menusection_']")
    sections.forEach(anchor => {
      // Each section anchor is followed by sibling elements until the next anchor
      const sectionId = anchor.id
      // Find the items row for this section
      const itemsRow = container.querySelector(`[data-testid="menu-items-row-${sectionId.replace('menusection_', '')}"]`)
      if (!itemsRow) return

      const visibleItems = itemsRow.querySelectorAll(".menu-item-card-mobile:not(.search-hidden)")
      const sectionHidden = query && visibleItems.length === 0

      // Hide the section header + items row
      // Walk backwards from itemsRow to find the section header elements
      let el = anchor.nextElementSibling
      while (el && el !== itemsRow) {
        el.classList.toggle("search-hidden", sectionHidden)
        el = el.nextElementSibling
      }
      anchor.classList.toggle("search-hidden", sectionHidden)
      itemsRow.classList.toggle("search-section-hidden", sectionHidden)
    })

    // Show/hide no-results message
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.toggle("d-none", !query || totalVisible > 0)
    }
  }
}
