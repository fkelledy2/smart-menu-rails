import { Controller } from "@hotwired/stimulus"

/**
 * Square Web Payments SDK Stimulus Controller
 *
 * Handles inline card payments via Square's Web Payments SDK.
 * Loads the SDK, initializes Card (+ Apple Pay / Google Pay when eligible),
 * tokenizes on submit, and POSTs to the server.
 *
 * Usage:
 *   <div data-controller="square-payment"
 *        data-square-payment-application-id-value="sandbox-sq0idb-..."
 *        data-square-payment-location-id-value="L..."
 *        data-square-payment-order-id-value="123"
 *        data-square-payment-currency-value="EUR"
 *        data-square-payment-amount-cents-value="2500"
 *        data-square-payment-sandbox-value="true">
 *     <div data-square-payment-target="cardContainer"></div>
 *     <div data-square-payment-target="applePayContainer"></div>
 *     <div data-square-payment-target="googlePayContainer"></div>
 *     <div data-square-payment-target="errorMessage" class="d-none"></div>
 *     <div data-square-payment-target="processingOverlay" class="d-none"></div>
 *     <button data-square-payment-target="submitButton"
 *             data-action="click->square-payment#pay">Pay</button>
 *   </div>
 */
export default class extends Controller {
  static targets = [
    "cardContainer",
    "applePayContainer",
    "googlePayContainer",
    "submitButton",
    "tipInput",
    "errorMessage",
    "processingOverlay",
  ]

  static values = {
    applicationId: String,
    locationId: String,
    orderId: String,
    currency: { type: String, default: "EUR" },
    amountCents: { type: Number, default: 0 },
    sandbox: { type: Boolean, default: true },
    paymentUrl: String, // override POST URL if needed
  }

  async connect() {
    this.card = null
    this.applePay = null
    this.googlePay = null
    this.payments = null

    try {
      await this.#loadSdk()
      await this.#initializePayments()
    } catch (e) {
      console.error("[SquarePayment] Initialization failed:", e)
      this.#showError("Payment system failed to load. Please refresh and try again.")
    }
  }

  disconnect() {
    this.card?.destroy?.()
    this.applePay?.destroy?.()
    this.googlePay?.destroy?.()
  }

  // ── Actions ────────────────────────────────────────────────────────

  async pay(event) {
    event?.preventDefault()

    if (!this.card) {
      this.#showError("Card payment is not ready. Please wait or refresh.")
      return
    }

    this.#setProcessing(true)
    this.#clearError()

    try {
      const tokenResult = await this.card.tokenize()

      if (tokenResult.status !== "OK") {
        const errorMsg = tokenResult.errors
          ?.map((e) => e.message)
          .join(", ") || "Card tokenization failed"
        this.#showError(errorMsg)
        this.#setProcessing(false)
        return
      }

      const sourceId = tokenResult.token
      let verificationToken = null

      // Buyer verification (SCA) — optional
      try {
        verificationToken = await this.#verifyBuyer(sourceId)
      } catch (verifyErr) {
        console.warn("[SquarePayment] Buyer verification skipped:", verifyErr)
      }

      await this.#submitPayment(sourceId, verificationToken)
    } catch (e) {
      console.error("[SquarePayment] Payment failed:", e)
      this.#showError("Payment failed. Please try again.")
      this.#setProcessing(false)
    }
  }

  // ── SDK Loading ────────────────────────────────────────────────────

  async #loadSdk() {
    if (window.Square) return

    const sdkUrl = this.sandboxValue
      ? "https://sandbox.web.squarecdn.com/v1/square.js"
      : "https://web.squarecdn.com/v1/square.js"

    return new Promise((resolve, reject) => {
      // Check if script is already loading
      if (document.querySelector(`script[src="${sdkUrl}"]`)) {
        const check = setInterval(() => {
          if (window.Square) { clearInterval(check); resolve() }
        }, 100)
        setTimeout(() => { clearInterval(check); reject(new Error("SDK load timeout")) }, 10000)
        return
      }

      const script = document.createElement("script")
      script.src = sdkUrl
      script.onload = () => resolve()
      script.onerror = () => reject(new Error("Failed to load Square SDK"))
      document.head.appendChild(script)
    })
  }

  // ── Payments Initialization ────────────────────────────────────────

  async #initializePayments() {
    if (!window.Square) throw new Error("Square SDK not loaded")

    this.payments = window.Square.payments(
      this.applicationIdValue,
      this.locationIdValue
    )

    // Card
    if (this.hasCardContainerTarget) {
      this.card = await this.payments.card()
      await this.card.attach(this.cardContainerTarget)
    }

    // Apple Pay
    if (this.hasApplePayContainerTarget) {
      try {
        const request = this.#buildPaymentRequest()
        this.applePay = await this.payments.applePay(request)
        // Apple Pay renders its own button inside the container
        this.applePayContainerTarget.classList.remove("d-none")
      } catch (e) {
        console.info("[SquarePayment] Apple Pay not available:", e.message)
        this.applePayContainerTarget.classList.add("d-none")
      }
    }

    // Google Pay
    if (this.hasGooglePayContainerTarget) {
      try {
        const request = this.#buildPaymentRequest()
        this.googlePay = await this.payments.googlePay(request)
        await this.googlePay.attach(this.googlePayContainerTarget)
        this.googlePayContainerTarget.classList.remove("d-none")
      } catch (e) {
        console.info("[SquarePayment] Google Pay not available:", e.message)
        this.googlePayContainerTarget.classList.add("d-none")
      }
    }
  }

  #buildPaymentRequest() {
    return this.payments.paymentRequest({
      countryCode: "IE",
      currencyCode: this.currencyValue.toUpperCase(),
      total: {
        amount: (this.amountCentsValue / 100).toFixed(2),
        label: "Total",
      },
    })
  }

  // ── Buyer Verification (SCA) ───────────────────────────────────────

  async #verifyBuyer(sourceId) {
    if (!this.payments?.verifyBuyer) return null

    const result = await this.payments.verifyBuyer(sourceId, {
      amount: (this.amountCentsValue / 100).toFixed(2),
      billingContact: {},
      currencyCode: this.currencyValue.toUpperCase(),
      intent: "CHARGE",
    })

    return result?.token || null
  }

  // ── Server Submission ──────────────────────────────────────────────

  async #submitPayment(sourceId, verificationToken) {
    const tipCents = this.hasTipInputTarget
      ? parseInt(this.tipInputTarget.value || "0", 10)
      : 0

    const url = this.paymentUrlValue ||
      `/smartmenu/orders/${this.orderIdValue}/payments`

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const body = {
      source_id: sourceId,
      verification_token: verificationToken,
      tip_cents: tipCents,
      amount_cents: this.amountCentsValue,
      currency: this.currencyValue,
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || "",
      },
      body: JSON.stringify(body),
    })

    const data = await response.json()

    if (data.ok || data.status === "succeeded") {
      this.#showSuccess()
    } else {
      this.#showError(data.error || "Payment was not completed.")
      this.#setProcessing(false)
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────

  #setProcessing(active) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = active
      this.submitButtonTarget.textContent = active ? "Processing…" : "Pay"
    }
    if (this.hasProcessingOverlayTarget) {
      this.processingOverlayTarget.classList.toggle("d-none", !active)
    }
  }

  #showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove("d-none")
    }
  }

  #clearError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = ""
      this.errorMessageTarget.classList.add("d-none")
    }
  }

  #showSuccess() {
    this.#setProcessing(false)
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.textContent = "Paid ✓"
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.remove("btn-primary")
      this.submitButtonTarget.classList.add("btn-success")
    }
    // Dispatch custom event for other controllers to react
    this.element.dispatchEvent(
      new CustomEvent("square-payment:success", { bubbles: true })
    )
  }
}
