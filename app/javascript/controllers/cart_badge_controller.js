import { Controller } from "@hotwired/stimulus"

/**
 * Cart Badge Controller
 * Animates the cart item count badge when items are added/removed.
 * Listens for custom "cart:updated" events dispatched by the ordering system.
 *
 * Usage:
 *   <span data-controller="cart-badge"
 *         data-cart-badge-target="count"
 *         data-action="cart:updated@document->cart-badge#update">
 *     0
 *   </span>
 */
export default class extends Controller {
  static targets = ["count"]

  update(event) {
    const { itemCount, totalFormatted } = event.detail || {}

    if (this.hasCountTarget && itemCount !== undefined) {
      this.countTarget.textContent = itemCount

      // Toggle visibility
      if (itemCount > 0) {
        this.countTarget.classList.remove("d-none")
      } else {
        this.countTarget.classList.add("d-none")
      }

      // Bounce animation
      this.countTarget.classList.remove("cart-badge-bounce")
      // Force reflow to restart animation
      void this.countTarget.offsetWidth
      this.countTarget.classList.add("cart-badge-bounce")
    }

    // Update total display if present
    const totalEl = document.getElementById("cartTotalAmount")
    if (totalEl && totalFormatted) {
      totalEl.textContent = totalFormatted
    }

    const totalVal = document.getElementById("cartTotalValue")
    if (totalVal && totalFormatted) {
      totalVal.textContent = totalFormatted
    }

    const countEl = document.getElementById("cartItemCount")
    if (countEl && itemCount !== undefined) {
      countEl.textContent = itemCount
    }
  }
}
