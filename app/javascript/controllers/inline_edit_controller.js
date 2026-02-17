import { Controller } from "@hotwired/stimulus"

/**
 * Inline Edit Stimulus Controller
 * Enables click-to-edit for table cells. Sends PATCH request on blur/Enter.
 *
 * Usage:
 *   <tr data-controller="inline-edit"
 *       data-inline-edit-url-value="/restaurants/1/menus/2/menusections/3/menuitems/4">
 *     <td data-inline-edit-target="cell"
 *         data-field="name"
 *         data-action="click->inline-edit#edit">
 *       Item Name
 *     </td>
 *     <td data-inline-edit-target="cell"
 *         data-field="price"
 *         data-action="click->inline-edit#edit">
 *       12.99
 *     </td>
 *   </tr>
 */
export default class extends Controller {
  static targets = ["cell"]
  static values = {
    url: String
  }

  connect() {
    this.editing = false
    this._cancelled = false
  }

  edit(event) {
    const cell = event.currentTarget
    if (cell.querySelector("input, textarea")) return // already editing

    const field = cell.dataset.field
    const currentValue = cell.dataset.value ?? cell.textContent.trim()
    const isPrice = field === "price" || field === "tasting_supplement_cents"
    const isDescription = field === "description"

    // Store original for cancel
    this._cancelled = false
    cell.dataset.originalHtml = cell.innerHTML

    // Create input
    let input
    if (isDescription) {
      input = document.createElement("textarea")
      input.rows = 2
      input.className = "form-control form-control-sm"
    } else {
      input = document.createElement("input")
      input.type = isPrice ? "number" : "text"
      input.step = isPrice ? "0.01" : undefined
      input.min = isPrice ? "0" : undefined
      input.className = "form-control form-control-sm"
    }

    input.value = currentValue
    input.dataset.field = field
    input.style.minWidth = "80px"

    cell.innerHTML = ""
    cell.appendChild(input)
    input.focus()
    input.select()

    // Save on blur or Enter
    input.addEventListener("blur", () => this.save(cell, input))
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !isDescription) {
        e.preventDefault()
        input.blur()
      }
      if (e.key === "Escape") {
        this._cancelled = true
        this.cancel(cell)
      }
    })
  }

  async save(cell, input) {
    // Skip save if edit was cancelled via Escape
    if (this._cancelled) return

    const field = input.dataset.field
    const newValue = input.value.trim()
    const originalHtml = cell.dataset.originalHtml

    // If value unchanged, just cancel
    if (newValue === (cell.dataset.value ?? "").trim()) {
      this.cancel(cell)
      return
    }

    // Optimistic update — show the new value immediately
    cell.innerHTML = this.formatDisplay(field, newValue)
    cell.dataset.value = newValue

    // Build payload
    const body = {}
    if (field === "price") {
      body.menuitem = { price: parseFloat(newValue) || 0 }
    } else if (field === "tasting_supplement_cents") {
      body.menuitem = { tasting_supplement_cents: Math.round((parseFloat(newValue) || 0) * 100) }
    } else {
      body.menuitem = { [field]: newValue }
    }

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken(),
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: JSON.stringify(body)
      })

      if (response.ok) {
        this.showIndicator("✓ Saved", "success")
      } else {
        // Revert on failure
        cell.innerHTML = originalHtml
        this.showIndicator("⚠ Save failed", "error")
      }
    } catch (error) {
      cell.innerHTML = originalHtml
      this.showIndicator("⚠ Save failed", "error")
      console.error("[InlineEdit] Save error:", error)
    }
  }

  cancel(cell) {
    if (cell.dataset.originalHtml) {
      cell.innerHTML = cell.dataset.originalHtml
    }
  }

  formatDisplay(field, value) {
    if (field === "description") {
      if (!value) return ""
      const truncated = value.length > 50 ? value.substring(0, 50) + "…" : value
      return `<div class="text-sm text-muted">${this.escapeHtml(truncated)}</div>`
    }
    return this.escapeHtml(value)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  showIndicator(text, state) {
    let indicator = document.getElementById("auto-save-indicator")
    if (!indicator) {
      indicator = document.createElement("div")
      indicator.id = "auto-save-indicator"
      indicator.className = "form-autosave-2025"
      document.body.appendChild(indicator)
    }
    indicator.textContent = text
    indicator.className = `form-autosave-2025 ${state}`
    setTimeout(() => {
      indicator.className = "form-autosave-2025"
    }, 2000)
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
