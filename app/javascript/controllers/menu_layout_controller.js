import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "cardBtn", "listBtn"]

  connect() {
    const saved = localStorage.getItem("smartmenu-layout")
    this.applyLayout(saved === "card" ? "card" : "list")
    
    this.observer = new MutationObserver(() => {
      const newCount = this.containerTargets.length;
      if (newCount > 0 && this.lastContainerCount !== newCount) {
        this.lastContainerCount = newCount;
        this.applyLayout(localStorage.getItem("smartmenu-layout") || "list");
      }
    });
    
    this.observer.observe(this.element, { childList: true, subtree: true });
    this.lastContainerCount = 0;
  }
  
  disconnect() {
    if (this.observer) this.observer.disconnect();
  }

  setCard() {
    this.applyLayout("card")
  }

  setList() {
    this.applyLayout("list")
  }

  applyLayout(mode) {
    localStorage.setItem("smartmenu-layout", mode)

    this.containerTargets.forEach((el, i) => {
      el.classList.toggle("menu-layout-list", mode === "list")
      el.classList.toggle("menu-layout-card", mode === "card")
    })

    if (this.hasCardBtnTarget) {
      this.cardBtnTargets.forEach((btn) => btn.classList.toggle("active", mode === "card"))
    }
    if (this.hasListBtnTarget) {
      this.listBtnTargets.forEach((btn) => btn.classList.toggle("active", mode === "list"))
    }
  }
}
