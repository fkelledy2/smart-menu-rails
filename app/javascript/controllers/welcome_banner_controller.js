import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "compact", "helpTip"]
  static values = { key: String }

  connect() {
    if (this._isDismissed()) {
      this.bannerTarget.classList.add("d-none")
    }
  }

  dismiss() {
    this.bannerTarget.classList.add("dismissing")
    setTimeout(() => {
      this.bannerTarget.classList.add("d-none")
      localStorage.setItem(this._storageKey(), "true")
    }, 300)
  }

  showDetails() {
    const modal = new bootstrap.Modal(document.getElementById("helpModal"))
    modal.show()
  }

  dismissTip() {
    if (!this.hasHelpTipTarget) return
    this.helpTipTarget.classList.add("dismissing")
    setTimeout(() => this.helpTipTarget.classList.add("d-none"), 300)
  }

  _isDismissed() {
    return localStorage.getItem(this._storageKey()) === "true"
  }

  _storageKey() {
    return "welcomeBannerDismissed_" + (this.keyValue || "")
  }
}
