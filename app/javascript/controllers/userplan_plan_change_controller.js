import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "submit"]
  static values = {
    currentPlanId: Number,
  }

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasSelectTarget || !this.hasSubmitTarget) return

    const selected = this.selectTarget.value
    const current = String(this.currentPlanIdValue || "")

    const changed = selected && current && selected !== current
    this.submitTarget.disabled = !changed
  }
}
