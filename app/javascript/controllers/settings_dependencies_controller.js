import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    stripeConnectEnabled: Boolean,
    morEnabled: Boolean,
  }

  static targets = ["displayImagesPopupRow", "ageVerificationRow", "allowOrderingRow"]

  connect() {
    this.displayImagesToggle = this.element.querySelector("#restaurant_displayImages")
    this.displayImagesPopupToggle = this.element.querySelector(
      "#restaurant_displayImagesInPopup"
    )

    this.allowAlcoholToggle = this.element.querySelector("#restaurant_allow_alcohol")
    this.ageVerificationToggle = this.element.querySelector("#enable_age_verification")

    this.allowOrderingToggle = this.element.querySelector("#restaurant_allowOrdering")

    this.syncAll = this.syncAll.bind(this)

    if (this.displayImagesToggle) {
      this.displayImagesToggle.addEventListener("change", this.syncAll)
    }
    if (this.allowAlcoholToggle) {
      this.allowAlcoholToggle.addEventListener("change", this.syncAll)
    }

    this.syncAll()
  }

  disconnect() {
    if (this.displayImagesToggle) {
      this.displayImagesToggle.removeEventListener("change", this.syncAll)
    }
    if (this.allowAlcoholToggle) {
      this.allowAlcoholToggle.removeEventListener("change", this.syncAll)
    }
  }

  syncAll() {
    this.syncDisplayImagesPopup()
    this.syncAgeVerification()
    this.syncAllowOrdering()
  }

  syncDisplayImagesPopup() {
    const parentOn = !!this.displayImagesToggle?.checked

    if (this.hasDisplayImagesPopupRowTarget) {
      this.displayImagesPopupRowTarget.classList.toggle("d-none", !parentOn)
    }

    if (this.displayImagesPopupToggle) {
      this.displayImagesPopupToggle.disabled = !parentOn
      if (!parentOn) {
        this.displayImagesPopupToggle.checked = false
        this.displayImagesPopupToggle.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }

  syncAgeVerification() {
    const parentOn = !!this.allowAlcoholToggle?.checked

    if (this.hasAgeVerificationRowTarget) {
      this.ageVerificationRowTarget.classList.toggle("d-none", !parentOn)
    }

    if (this.ageVerificationToggle) {
      this.ageVerificationToggle.disabled = !parentOn
      if (!parentOn) {
        this.ageVerificationToggle.checked = false
      }
    }
  }

  syncAllowOrdering() {
    const prerequisitesMet = !!this.morEnabledValue

    if (this.hasAllowOrderingRowTarget) {
      this.allowOrderingRowTarget.classList.toggle("d-none", !prerequisitesMet)
    }

    if (this.allowOrderingToggle) {
      this.allowOrderingToggle.disabled = !prerequisitesMet
      if (!prerequisitesMet) {
        this.allowOrderingToggle.checked = false
        this.allowOrderingToggle.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }
}
