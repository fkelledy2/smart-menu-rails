import { Controller } from "@hotwired/stimulus"

/**
 * Menu Search Controller
 * Client-side filtering of menu items by name/description.
 * Works with existing data-name and data-description attributes on .menu-item-card-mobile elements.
 *
 * Usage:
 *   <div data-controller="menu-search">
 *     <input data-menu-search-target="input" data-action="input->menu-search#filter" placeholder="Search menu…">
 *     <button data-menu-search-target="clear" data-action="click->menu-search#clear" class="d-none">✕</button>
 *     <div data-menu-search-target="container">
 *       <!-- menu sections and items rendered here -->
 *     </div>
 *     <div data-menu-search-target="empty" class="d-none">No items found</div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["input", "clear", "container", "empty"]

  connect() {
    this._debounceTimer = null
  }

  disconnect() {
    if (this._debounceTimer) clearTimeout(this._debounceTimer)
  }

  filter() {
    if (this._debounceTimer) clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(() => this._applyFilter(), 150)
  }

  clear() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
    this._applyFilter()
  }

  _applyFilter() {
    const query = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()

    // Toggle clear button visibility
    if (this.hasClearTarget) {
      this.clearTarget.classList.toggle("d-none", query.length === 0)
    }

    const container = this.hasContainerTarget ? this.containerTarget : this.element
    const items = container.querySelectorAll(".menu-item-card-mobile")
    const sections = container.querySelectorAll('[id^="menusection_"]')

    let totalVisible = 0

    if (query.length === 0) {
      // Show everything
      items.forEach(item => { item.style.display = "" })
      sections.forEach(sec => {
        sec.style.display = ""
        // Also show the section content that follows the anchor div
        this._setSectionVisibility(sec, true)
      })
      totalVisible = items.length
    } else {
      // Filter items
      items.forEach(item => {
        const name = (item.dataset.name || "").toLowerCase()
        const desc = (item.dataset.description || "").toLowerCase()
        const match = name.includes(query) || desc.includes(query)
        item.style.display = match ? "" : "none"
        if (match) totalVisible++
      })

      // Hide sections with no visible items
      sections.forEach(sec => {
        const hasVisible = this._sectionHasVisibleItems(sec)
        sec.style.display = hasVisible ? "" : "none"
        this._setSectionVisibility(sec, hasVisible)
      })
    }

    // Show/hide empty state
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("d-none", totalVisible > 0 || query.length === 0)
    }
  }

  /**
   * Check if a section anchor's sibling content has any visible menu items.
   * Section anchors are: <div id="menusection_123">
   * The actual content (header + items row) follows as siblings.
   */
  _sectionHasVisibleItems(sectionAnchor) {
    // Walk siblings until next section anchor or end
    let el = sectionAnchor.nextElementSibling
    while (el) {
      if (el.id && el.id.startsWith("menusection_")) break
      const visibleItems = el.querySelectorAll('.menu-item-card-mobile:not([style*="display: none"])')
      if (visibleItems.length > 0) return true
      el = el.nextElementSibling
    }
    return false
  }

  /**
   * Show/hide sibling elements between this section anchor and the next one.
   */
  _setSectionVisibility(sectionAnchor, visible) {
    let el = sectionAnchor.nextElementSibling
    while (el) {
      if (el.id && el.id.startsWith("menusection_")) break
      el.style.display = visible ? "" : "none"
      el = el.nextElementSibling
    }
  }
}
