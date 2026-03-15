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
    console.log('[menu-layout] Controller connected');
    console.log('[menu-layout] Container targets:', this.containerTargets.length);
    console.log('[menu-layout] Card button targets:', this.cardBtnTargets.length);
    console.log('[menu-layout] List button targets:', this.listBtnTargets.length);
    
    const saved = localStorage.getItem("smartmenu-layout")
    // Default to list layout (mobile-first, Deliveroo/Uber Eats style)
    this.applyLayout(saved === "card" ? "card" : "list")
    
    // Watch for menu sections being added to DOM (they're in cached fragment)
    this.observer = new MutationObserver(() => {
      const newCount = this.containerTargets.length;
      if (newCount > 0 && this.lastContainerCount !== newCount) {
        console.log('[menu-layout] New containers detected:', newCount);
        this.lastContainerCount = newCount;
        // Reapply layout to new containers
        const currentMode = localStorage.getItem("smartmenu-layout") || "list";
        this.applyLayout(currentMode);
      }
    });
    
    this.observer.observe(this.element, { childList: true, subtree: true });
    this.lastContainerCount = 0;
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  setCard() {
    console.log('[menu-layout] setCard() called');
    this.applyLayout("card")
  }

  setList() {
    console.log('[menu-layout] setList() called');
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
