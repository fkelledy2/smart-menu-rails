import { Controller } from "@hotwired/stimulus"

/**
 * Menu Layout Controller
 * Toggles between card and list layout on the customer smartmenu.
 * Persists preference in localStorage.
 *
 * Usage:
 * <div data-controller="menu-layout">
 *   <button data-action="click->menu-layout#setCard" data-menu-layout-target="cardBtn">Cards</button>
 *   <button data-action="click->menu-layout#setList" data-menu-layout-target="listBtn">List</button>
 *   <div data-menu-layout-target="container">…items…</div>
 * </div>
 */
export default class extends Controller {
  static targets = ["container", "cardBtn", "listBtn"]

  static STORAGE_KEY = "smartmenu-layout"

  connect() {
    const saved = localStorage.getItem("smartmenu-layout")
    this.applyLayout(saved === "list" ? "list" : "card")
  }

  setCard() {
    this.applyLayout("card")
  }

  setList() {
    this.applyLayout("list")
  }

  applyLayout(mode) {
    localStorage.setItem("smartmenu-layout", mode)

    // Toggle class on every container target (one per section row)
    this.containerTargets.forEach((el) => {
      el.classList.toggle("menu-layout-list", mode === "list")
      el.classList.toggle("menu-layout-card", mode === "card")
    })

    // Update button active states
    if (this.hasCardBtnTarget) {
      this.cardBtnTargets.forEach((btn) => btn.classList.toggle("active", mode === "card"))
    }
    if (this.hasListBtnTarget) {
      this.listBtnTargets.forEach((btn) => btn.classList.toggle("active", mode === "list"))
    }
  }
}
