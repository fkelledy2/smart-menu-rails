import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "statusSelect", "submit"]

  enabledCheckboxes() {
    return this.checkboxTargets.filter((cb) => !cb.disabled)
  }

  connect() {
    this.sync()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.enabledCheckboxes().forEach((cb) => {
      cb.checked = checked
    })
    this.sync()
  }

  sync() {
    const enabled = this.enabledCheckboxes()
    const anySelected = enabled.some((cb) => cb.checked)
    const statusSelected = this.hasStatusSelectTarget
      ? ((this.statusSelectTarget.value || "").length > 0)
      : true

    if (this.submitTarget) {
      this.submitTarget.disabled = !(anySelected && statusSelected)
    }

    if (this.selectAllTarget) {
      const allChecked = enabled.length > 0 && enabled.every((cb) => cb.checked)
      const someChecked = enabled.some((cb) => cb.checked)

      this.selectAllTarget.checked = allChecked
      // Indeterminate state when some but not all selected
      this.selectAllTarget.indeterminate = someChecked && !allChecked
    }
  }

  beforeSubmit(event) {
    // Prevent submits that would no-op (UX safety)
    const anySelected = this.enabledCheckboxes().some((cb) => cb.checked)
    const statusSelected = this.hasStatusSelectTarget
      ? ((this.statusSelectTarget.value || "").length > 0)
      : true
    if (!(anySelected && statusSelected)) {
      event.preventDefault()
    }
  }
}
