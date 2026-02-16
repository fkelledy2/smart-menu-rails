import { Controller } from "@hotwired/stimulus"

/**
 * AI Progress Controller
 * Handles AI image generation, AI polish, and menu localization workflows.
 * Replaces ~418 lines of inline <script> in menus/edit_2025.html.erb.
 *
 * Usage:
 *   <div data-controller="ai-progress"
 *        data-ai-progress-csrf-value="<%= form_authenticity_token %>">
 *     <!-- forms with data-action="submit->ai-progress#intercept" -->
 *     <!-- modal with targets -->
 *   </div>
 */
export default class extends Controller {
  static targets = [
    "modal",
    "confirmPane",
    "progressPane",
    "confirmBtn",
    "progressText",
    "progressBar",
    "preview",
    "previewImg",
    "logWrap",
    "logItems",
    "localizeOptions",
    "modalTitle",
    "confirmText"
  ]

  static values = {
    csrf: String
  }

  connect() {
    this.pendingForm = null
    this.pollTimer = null
    this.currentJobId = null
    this.currentMode = "ai" // "ai" | "localize" | "polish"
    this.lastLogStamp = null

    this._cleanupTomSelect()
    this._bindAutosave()

    // Listen for Turbo events
    this._turboLoadHandler = () => {
      this._cleanupTomSelect()
      this._bindAutosave()
    }
    document.addEventListener("turbo:load", this._turboLoadHandler)
    document.addEventListener("turbo:frame-load", this._turboLoadHandler)
  }

  disconnect() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
    document.removeEventListener("turbo:load", this._turboLoadHandler)
    document.removeEventListener("turbo:frame-load", this._turboLoadHandler)
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /**
   * Intercept form submission — show confirm modal instead.
   * Only processes forms with data-ai-generate, data-localize, or data-polish.
   * Attach via: data-action="submit->ai-progress#intercept"
   */
  intercept(event) {
    const form = event.target
    if (!form || !form.matches) return
    const isAi = form.matches('form[data-ai-generate="true"]')
    const isLocalize = form.matches('form[data-localize="true"]')
    const isPolish = form.matches('form[data-polish="true"]')
    if (!isAi && !isLocalize && !isPolish) return

    event.preventDefault()
    this.pendingForm = form
    this.currentMode = isLocalize ? "localize" : (isPolish ? "polish" : "ai")
    this._showConfirmModal()
  }

  /**
   * User clicks Confirm — start the job
   * Attach via: data-action="click->ai-progress#confirm"
   */
  confirm() {
    if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = true
    this._startJob()
  }

  /**
   * Modal dismissed — clean up
   * Attach via: data-action="hidden.bs.modal->ai-progress#dismiss"
   */
  dismiss() {
    this.pendingForm = null
  }

  // ── Private ──────────────────────────────────────────────────────────

  _showConfirmModal() {
    const modalEl = this.modalTarget

    // Move modal to body once to avoid stacking context issues
    if (!modalEl.dataset.movedToBody) {
      document.body.appendChild(modalEl)
      modalEl.dataset.movedToBody = "true"
    }

    // Show confirm pane, hide progress pane
    this.confirmPaneTarget.classList.remove("d-none")
    this.confirmPaneTarget.style.display = ""
    this.progressPaneTarget.classList.add("d-none")
    this.progressPaneTarget.style.display = "none"

    // Set title per mode
    const titles = { localize: "Translate Menu", polish: "AI Polish Menu", ai: "Generate AI Images" }
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = titles[this.currentMode] || titles.ai
    }

    // Set confirmation text per mode
    const texts = {
      localize: "This will translate your menu to active restaurant locales and may consume API credits. Proceed?",
      polish: "This will clean up item names/descriptions, generate missing descriptions with AI, assess allergens/alcohol and reorder sections. Proceed?",
      ai: "This will generate new AI images for your menu items and may consume API credits. AI Polish is strongly recommended first for best results. Proceed?"
    }
    if (this.hasConfirmTextTarget) {
      this.confirmTextTarget.textContent = texts[this.currentMode] || texts.ai
    }

    // Hide image preview for localization/polish modes
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = (this.currentMode === "localize" || this.currentMode === "polish") ? "none" : ""
    }

    // Clear log
    if (this.hasLogItemsTarget) this.logItemsTarget.innerHTML = ""
    if (this.hasLogWrapTarget) {
      this.logWrapTarget.classList.toggle("d-none", !(this.currentMode === "localize" || this.currentMode === "polish"))
    }

    // Show localization options only in localize mode
    if (this.hasLocalizeOptionsTarget) {
      this.localizeOptionsTarget.style.display = this.currentMode === "localize" ? "" : "none"
      if (this.currentMode === "localize") {
        const missing = this.localizeOptionsTarget.querySelector("#localize-missing")
        const force = this.localizeOptionsTarget.querySelector("#localize-force")
        if (missing) missing.checked = true
        if (force) force.checked = false
      }
    }

    if (this.hasConfirmBtnTarget) this.confirmBtnTarget.disabled = false

    const modal = bootstrap.Modal.getOrCreateInstance(modalEl)
    modal.show()
  }

  async _startJob() {
    if (!this.pendingForm) return

    // Swap to progress pane
    this.confirmPaneTarget.classList.add("d-none")
    this.confirmPaneTarget.style.display = "none"
    this.progressPaneTarget.classList.remove("d-none")
    this.progressPaneTarget.style.display = ""

    const queuedTexts = { localize: "Queued localization…", polish: "Queued polishing…", ai: "Queued…" }
    this.progressTextTarget.textContent = queuedTexts[this.currentMode] || queuedTexts.ai
    this._updateBar(0)

    if (this.hasLogItemsTarget) this.logItemsTarget.innerHTML = ""

    const url = this.pendingForm.action
    const formData = new FormData(this.pendingForm)

    try {
      const u = new URL(url, window.location.origin)
      u.pathname = u.pathname.endsWith(".json") ? u.pathname : (u.pathname + ".json")

      if (this.currentMode === "localize") {
        const selected = this.element.querySelector('input[name="localizeMode"]:checked')?.value || "missing"
        u.searchParams.set("force", selected === "force" ? "true" : "false")
      }

      const resp = await fetch(u.toString(), {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfValue, "Accept": "application/json" },
        body: formData
      })

      const ct = resp.headers.get("Content-Type") || ""
      let data = null
      const text = await resp.text()
      if (text && ct.includes("application/json")) {
        try { data = JSON.parse(text) } catch (e) { console.warn("JSON parse failed", e, text) }
      }

      if (data && data.job_id) {
        this.currentJobId = data.job_id
        this._pollProgress(this.pendingForm, data.job_id)
      } else {
        const msg = resp.status >= 400 ? `Failed to start job (HTTP ${resp.status})` : "Failed to start job"
        this.progressTextTarget.textContent = msg
      }
    } catch (e) {
      this.progressTextTarget.textContent = "Error starting job"
      console.error(e)
    }
  }

  _updateBar(percent) {
    if (!this.hasProgressBarTarget) return
    this.progressBarTarget.style.width = percent + "%"
    this.progressBarTarget.setAttribute("aria-valuenow", percent)
  }

  /**
   * Unified poll function for all three modes (ai, polish, localize).
   * Replaces the three near-identical pollProgress/pollPolishProgress/pollLocalizationProgress.
   */
  _pollProgress(form, jobId) {
    const base = new URL(form.action, window.location.origin)

    // Determine progress endpoint based on mode
    if (this.currentMode === "localize") {
      base.pathname = base.pathname.replace(/\/localize(\.json)?$/, "/localization_progress")
    } else if (this.currentMode === "polish") {
      base.pathname = base.pathname.replace(/\/(polish)(\.json)?$/, "/polish_progress")
    } else {
      base.pathname = base.pathname.replace(/\/regenerate_images(\.json)?$/, "/image_generation_progress")
    }
    base.searchParams.set("job_id", jobId)
    const url = base.toString()

    this.lastLogStamp = null

    if (this.pollTimer) { clearInterval(this.pollTimer) }

    this.pollTimer = setInterval(async () => {
      try {
        const resp = await fetch(url, { headers: { "Accept": "application/json" } })
        if (!resp.ok) return
        const p = await resp.json()

        const current = p.current || 0
        const total = p.total || 0
        const status = p.status || "running"
        const percent = total > 0 ? Math.floor((current / total) * 100) : (status === "completed" ? 100 : 0)
        this._updateBar(percent)

        // Build progress text based on mode
        let progressText = ""
        if (this.currentMode === "localize") {
          const locale = p.current_locale || ""
          const displayLocale = this._formatLocale(locale)
          const baseMsg = p.message || (locale ? `Localized ${displayLocale}` : status)
          progressText = total > 0 ? `${baseMsg} — ${current}/${total}` : baseMsg
        } else if (this.currentMode === "polish") {
          const name = p.current_item_name || ""
          const msg = p.message || status
          const baseMsg = name || msg
          progressText = total > 0 ? `${baseMsg} — ${current}/${total}` : baseMsg
        } else {
          const name = p.current_item_name || ""
          progressText = name || (p.message || status)
        }
        this.progressTextTarget.textContent = progressText

        // Update log
        this._updateLog(p.log)

        // Update preview image (AI image generation mode only)
        if (this.currentMode === "ai" && p.current_item_image_url && this.hasPreviewTarget && this.hasPreviewImgTarget) {
          const normalized = (p.current_item_image_url || "").replace(/\\u0026/g, "&")
          const abs = new URL(normalized, window.location.origin)
          const hasS3Sig = abs.search.includes("X-Amz-") || abs.searchParams.has("X-Amz-Signature")
          const hasVersion = abs.searchParams.has("v")
          if (!hasS3Sig && !hasVersion) {
            abs.searchParams.set("t", Date.now().toString())
          }
          if (abs.searchParams.getAll("v").length > 1) {
            const v = abs.searchParams.getAll("v").pop()
            abs.searchParams.delete("v")
            abs.searchParams.set("v", v)
          }
          this.previewImgTarget.src = abs.toString()
          this.previewTarget.classList.remove("d-none")
          this.previewTarget.style.display = ""
        }

        // Check completion
        if (status === "completed" || status === "failed") {
          clearInterval(this.pollTimer)
          this.pollTimer = null
          if (status === "completed") {
            this.progressTextTarget.textContent = "Completed"
            this._updateBar(100)
            setTimeout(() => {
              const modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget)
              modal.hide()
            }, 900)
          }
        }
      } catch (e) {
        console.warn("Progress poll failed", e)
      }
    }, 1500)
  }

  _updateLog(log) {
    if (!this.hasLogItemsTarget || !Array.isArray(log) || log.length === 0) return

    const newest = log[log.length - 1]
    const newestStamp = newest && (newest.at || newest.message)
    if (newestStamp && newestStamp !== this.lastLogStamp) {
      this.lastLogStamp = newestStamp
      this.logItemsTarget.innerHTML = log
        .slice(-50)
        .map(row => {
          const msg = (row && row.message) ? row.message : ""
          return `<div class="mb-1">${msg.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")}</div>`
        })
        .join("")
      this.logItemsTarget.scrollTop = this.logItemsTarget.scrollHeight
    }
  }

  _formatLocale(locale) {
    try {
      if (locale && window.Intl && Intl.DisplayNames) {
        const dn = new Intl.DisplayNames([locale, "en"], { type: "language" })
        const n = dn.of(locale)
        if (n) return `${n} (${locale.toUpperCase()})`
      }
    } catch (_) {}
    return locale.toUpperCase()
  }

  /**
   * Defensive cleanup for any lingering TomSelect wrapper for menu status (Turbo cache safety)
   */
  _cleanupTomSelect() {
    try {
      const tsCtrl = document.getElementById("menu_status-ts-control")
      if (tsCtrl) {
        const wrap = tsCtrl.closest(".ts-wrapper")
        if (wrap) wrap.remove()
      }
      const sel = document.getElementById("menu_status")
      if (sel) {
        if (sel.tomselect && typeof sel.tomselect.destroy === "function") {
          try { sel.tomselect.destroy() } catch (_) {}
        }
        sel.remove()
      }
    } catch (_) {}
  }

  /**
   * Global auto-save: submit any form marked with data-auto-save on input changes
   */
  _bindAutosave() {
    if (document.documentElement.dataset.autosaveBound === "true") return
    document.addEventListener("change", function (e) {
      const target = e.target
      if (!target || !(target instanceof Element)) return
      const form = target.closest('form[data-auto-save="true"], form[data-auto-save=true]')
      if (!form) return
      if (target.matches("[data-no-autosave]")) return
      try {
        if (form.requestSubmit) { form.requestSubmit() }
        else { form.submit() }
      } catch (err) { console.warn("Auto-save submit failed", err) }
    }, true)
    document.documentElement.dataset.autosaveBound = "true"
  }
}
