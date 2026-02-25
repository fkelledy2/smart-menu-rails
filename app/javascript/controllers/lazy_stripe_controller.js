import { Controller } from "@hotwired/stimulus"

/**
 * Lazy Stripe Controller
 * Loads Stripe.js on demand — only when the user initiates a payment flow.
 * Eliminates ~40KB render-blocking JS on every smartmenu page load.
 *
 * Usage:
 *   <div data-controller="lazy-stripe"
 *        data-lazy-stripe-key-value="pk_live_xxx">
 *     <button data-action="click->lazy-stripe#load">Pay</button>
 *   </div>
 *
 * The controller dispatches "stripe:ready" on its element once Stripe is loaded,
 * so other controllers can listen: data-action="stripe:ready->payment#init"
 */
export default class extends Controller {
  static values = { key: String, src: { type: String, default: "https://js.stripe.com/v3" } }

  connect() {
    this._loaded = !!window.Stripe
  }

  load() {
    if (this._loaded || this._loading) return this._promise
    return this._loadStripe()
  }

  _loadStripe() {
    this._loading = true
    this._promise = new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = this.srcValue
      script.async = true
      script.onload = () => {
        this._loaded = true
        this._loading = false
        this.dispatch("ready", { detail: { stripe: window.Stripe(this.keyValue) } })
        resolve(window.Stripe)
      }
      script.onerror = () => {
        this._loading = false
        reject(new Error("Failed to load Stripe.js"))
      }
      document.head.appendChild(script)
    })
    return this._promise
  }
}
