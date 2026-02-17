import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details", "toggle", "chevron"]

  connect() {
    this.isOpen = this.detailsTarget.classList.contains("show")
    this.hoverCloseTimer = null

    // Auto-expand when arriving from onboarding flow
    if (new URLSearchParams(window.location.search).has("onboarding")) {
      requestAnimationFrame(() => this.open())
    }
  }

  disconnect() {
    if (this.hoverCloseTimer) clearTimeout(this.hoverCloseTimer)
  }

  toggle(event) {
    if (event) event.preventDefault()
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.hoverCloseTimer) {
      clearTimeout(this.hoverCloseTimer)
      this.hoverCloseTimer = null
    }

    const Collapse = window.bootstrap && window.bootstrap.Collapse
    if (!Collapse) return

    Collapse.getOrCreateInstance(this.detailsTarget, { toggle: false }).show()
    this.isOpen = true
    this.updateChevron()
    if (this.toggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    const Collapse = window.bootstrap && window.bootstrap.Collapse
    if (!Collapse) return

    this.hoverCloseTimer = setTimeout(() => {
      Collapse.getOrCreateInstance(this.detailsTarget, { toggle: false }).hide()
      this.isOpen = false
      this.updateChevron()
      if (this.toggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
    }, 120)
  }

  updateChevron() {
    if (!this.hasChevronTarget) return

    this.chevronTarget.style.transition = "transform 120ms ease"
    this.chevronTarget.style.transform = this.isOpen ? "rotate(90deg)" : "rotate(0deg)"
  }
}
