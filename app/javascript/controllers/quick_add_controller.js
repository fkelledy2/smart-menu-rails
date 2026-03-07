import { Controller } from "@hotwired/stimulus"

// Quick-add quantity stepper for staff view menu items.
// Provides a +/- stepper so staff can set quantity before tapping the add button.
// The selected quantity is stored on the add button as data-quick-add-qty and
// read by the modal confirm handler to post multiple items.
export default class extends Controller {
  static targets = ["qty", "decrement", "input"]

  connect() {
    this._quantity = 1
    this._updateDisplay()
  }

  increment(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this._quantity < 99) {
      this._quantity++
      this._updateDisplay()
    }
  }

  decrement(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this._quantity > 1) {
      this._quantity--
      this._updateDisplay()
    }
  }

  // Called when the main add button is clicked — store qty for the modal handler
  storeQty() {
    window.__quickAddQty = this._quantity
    // Reset after a short delay (modal will read it on confirm)
    setTimeout(() => { this._quantity = 1; this._updateDisplay() }, 500)
  }

  syncInput(event) {
    const nextQuantity = this._clampQuantity(event?.target?.value)
    this._quantity = nextQuantity
    this._updateDisplay()
  }

  _updateDisplay() {
    if (this.hasQtyTarget) {
      this.qtyTarget.textContent = this._quantity
    }
    if (this.hasInputTarget) {
      this.inputTarget.value = this._quantity
    }
    if (this.hasDecrementTarget) {
      this.decrementTarget.disabled = this._quantity <= 1
    }
  }

  _clampQuantity(value) {
    const parsed = parseInt(String(value || '1'), 10)
    if (Number.isNaN(parsed)) return 1
    return Math.max(1, Math.min(99, parsed))
  }
}
