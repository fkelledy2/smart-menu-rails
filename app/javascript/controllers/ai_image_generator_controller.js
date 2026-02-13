import { Controller } from "@hotwired/stimulus"

/**
 * AI Image Generator Stimulus Controller
 * Manages the AI image generation modal for menu items.
 * Replaces the inline <script> block from edit_2025.html.erb.
 *
 * Usage:
 *   <div data-controller="ai-image-generator">
 *     <a data-action="click->ai-image-generator#open"
 *        data-ai-image-generator-generate-url-param="/generate"
 *        data-ai-image-generator-status-url-param="/status"
 *        data-ai-image-generator-initial-updated-at-param="0"
 *        data-ai-image-generator-initial-image-url-param="">
 *       Generate Image
 *     </a>
 *     <!-- Modal targets -->
 *   </div>
 */
export default class extends Controller {
  static targets = [
    "modal",
    "confirmPane",
    "progressPane",
    "progressText",
    "progressBar",
    "preview",
    "previewImg",
    "confirmBtn"
  ]

  connect() {
    this.pending = null
    this.pollTimer = null
  }

  disconnect() {
    this.clearPoll()
  }

  open(event) {
    event.preventDefault()
    const link = event.currentTarget

    this.pending = {
      generateUrl: link.dataset.aiImageGeneratorGenerateUrlParam || link.dataset.generateUrl,
      statusUrl: link.dataset.aiImageGeneratorStatusUrlParam || link.dataset.statusUrl,
      initialUpdatedAt: parseInt(link.dataset.aiImageGeneratorInitialUpdatedAtParam || link.dataset.initialUpdatedAt || "0", 10),
      initialImageUrl: (link.dataset.aiImageGeneratorInitialImageUrlParam || link.dataset.initialImageUrl || "").toString()
    }

    this.resetUI()

    if (this.hasModalTarget && typeof bootstrap !== "undefined") {
      const modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget)
      modal.show()
    }
  }

  async confirm() {
    if (!this.pending) return

    if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = true
    if (this.hasConfirmPaneTarget) this.confirmPaneTarget.classList.add("d-none")
    if (this.hasProgressPaneTarget) this.progressPaneTarget.classList.remove("d-none")
    this.setText("Starting…")
    this.setProgress(25)

    try {
      const resp = await fetch(this.pending.generateUrl, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken(),
          "Accept": "application/json"
        }
      })

      if (!resp.ok) {
        this.setText(`Failed to start (HTTP ${resp.status})`)
        this.setProgress(100)
        if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = false
        return
      }

      this.setText("Queued…")
      this.setProgress(35)
      this.startPolling()
    } catch (e) {
      this.setText("Error starting generation")
      this.setProgress(100)
      if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = false
    }
  }

  dismiss() {
    this.clearPoll()
    this.resetUI()
  }

  // ── Private ────────────────────────────────────────────────────────

  startPolling() {
    if (!this.pending) return
    this.clearPoll()

    const { statusUrl, initialUpdatedAt, initialImageUrl } = this.pending

    this.pollTimer = setInterval(async () => {
      try {
        const resp = await fetch(statusUrl, { headers: { "Accept": "application/json" } })
        if (!resp.ok) return

        const data = await resp.json()
        const updatedAt = parseInt(data.updated_at || 0, 10)
        const hasImage = !!data.has_image
        const imageUrl = (data.image_url || "").toString()

        this.setText(hasImage ? "Generating…" : "Queued…")
        this.setProgress(hasImage ? 80 : 55)

        const imageChanged = imageUrl && imageUrl !== initialImageUrl
        const recordAdvanced = updatedAt > initialUpdatedAt

        if (imageChanged && recordAdvanced && this.hasPreviewTarget && this.hasPreviewImgTarget) {
          const normalized = imageUrl.replace(/\\u0026/g, "&")
          let finalUrl = normalized
          try {
            const u = new URL(normalized, window.location.origin)
            const hasS3Sig = u.search.includes("X-Amz-") || u.searchParams.has("X-Amz-Signature")
            if (!hasS3Sig) u.searchParams.set("t", Date.now().toString())
            finalUrl = u.toString()
          } catch (_) {
            finalUrl = normalized + (normalized.includes("?") ? "&" : "?") + "t=" + Date.now()
          }
          this.previewImgTarget.src = finalUrl
          this.previewTarget.classList.remove("d-none")
        }

        if (recordAdvanced && hasImage) {
          this.clearPoll()
          this.setText("Completed")
          this.setProgress(100)
          if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = false
        }
      } catch (_) {
        // Silently retry on next interval
      }
    }, 1500)
  }

  clearPoll() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  resetUI() {
    if (this.hasConfirmPaneTarget) this.confirmPaneTarget.classList.remove("d-none")
    if (this.hasProgressPaneTarget) this.progressPaneTarget.classList.add("d-none")
    this.setText("Queued…")
    this.setProgress(15)
    if (this.hasPreviewTarget) this.previewTarget.classList.add("d-none")
    if (this.hasPreviewImgTarget) this.previewImgTarget.src = ""
    if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = false
  }

  setText(text) {
    if (this.hasProgressTextTarget) this.progressTextTarget.textContent = text
  }

  setProgress(percent) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
      this.progressBarTarget.setAttribute("aria-valuenow", percent)
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
