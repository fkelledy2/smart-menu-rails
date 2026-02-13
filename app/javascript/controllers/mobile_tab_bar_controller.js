import { Controller } from "@hotwired/stimulus"

/**
 * Mobile Tab Bar Controller
 * Shows a fixed bottom navigation bar on small screens for quick section access.
 * Updates active state based on current URL section parameter.
 *
 * Usage:
 * <nav data-controller="mobile-tab-bar">
 *   <a data-mobile-tab-bar-target="tab" data-section="details" ...>
 * </nav>
 */
export default class extends Controller {
  static targets = ["tab"]

  connect() {
    this.updateActiveTab()
    this.boundUpdate = this.updateActiveTab.bind(this)
    document.addEventListener("turbo:frame-load", this.boundUpdate)
    window.addEventListener("popstate", this.boundUpdate)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.boundUpdate)
    window.removeEventListener("popstate", this.boundUpdate)
  }

  updateActiveTab() {
    const section = new URL(window.location.href).searchParams.get("section") || "details"

    this.tabTargets.forEach(tab => {
      const tabSection = tab.dataset.section
      if (tabSection === section) {
        tab.classList.add("active")
        tab.setAttribute("aria-current", "page")
      } else {
        tab.classList.remove("active")
        tab.removeAttribute("aria-current")
      }
    })
  }

  // Called on tab click — also opens sidebar full menu via "more" tab
  openSidebar(event) {
    event.preventDefault()
    const sidebarController = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller~='sidebar']"),
      "sidebar"
    )
    if (sidebarController) sidebarController.open()
  }
}
