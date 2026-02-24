import { Controller } from "@hotwired/stimulus"

/**
 * Sommelier Controller — Guest-facing "Help me choose" dual-flow.
 *
 * Supports two flows:
 *   - Spirits: smoky → taste → budget → /recommend
 *   - Wine:    color → style → budget → /recommend_wine
 *
 * Targets:
 *   panel      — the bottom-sheet / overlay container
 *   step       — each step screen (0=mode, 1-3=spirits, 4-6=wine)
 *   results    — results container
 *   loading    — spinner shown during fetch
 */
export default class extends Controller {
  static targets = ["panel", "step", "results", "loading", "footer"]
  static values  = {
    url: String,
    wineUrl: String,
    pairingsUrl: String,
    currency: { type: String, default: "EUR" },
    availability: { type: Object, default: {} },
  }

  connect() {
    this.mode = null // "spirits" or "wine"
    this.preferences = {}
    this.winePreferences = {}
    this.flowSteps = []
  }

  open() {
    this.mode = null
    this.preferences = { smoky: null, taste: null, budget: null }
    this.winePreferences = { wine_color: null, body: null, taste: null, budget: null }

    const avail = this.availabilityValue || {}
    const hasSpirits = (avail.spirits || 0) > 0
    const hasWine = (avail.wine || 0) > 0

    // Hide mode buttons that have zero items
    this._filterModeButtons(hasSpirits, hasWine)

    // Pre-filter wine color buttons
    this._filterWineColorButtons(avail.wine_colors || {})

    // Auto-select mode if only one category exists
    if (hasSpirits && !hasWine) {
      this.mode = "spirits"
      this.flowSteps = this._spiritsStepIndices()
    } else if (hasWine && !hasSpirits) {
      this.mode = "wine"
      this.flowSteps = this._wineStepIndices()
    } else {
      this.flowSteps = [0] // show mode selection
    }

    this.panelTarget.classList.remove("d-none")
    this.panelTarget.classList.add("sommelier-open")
    document.body.classList.add("sommelier-active")
    this._advanceFlow()
  }

  close() {
    this.panelTarget.classList.add("d-none")
    this.panelTarget.classList.remove("sommelier-open")
    document.body.classList.remove("sommelier-active")
  }

  // Step 0: Mode selection
  setMode(event) {
    this.mode = event.currentTarget.dataset.value
    if (this.mode === "wine") {
      this.flowSteps = this._wineStepIndices()
    } else {
      this.flowSteps = this._spiritsStepIndices()
    }
    this._advanceFlow()
  }

  // Hide mode buttons with zero items; if only one visible, auto-select it
  _filterModeButtons(hasSpirits, hasWine) {
    const modeStep = this.stepTargets[0]
    if (!modeStep) return
    const buttons = modeStep.querySelectorAll(".sommelier-option-btn[data-value]")
    buttons.forEach(btn => {
      const val = btn.dataset.value
      if (val === "spirits") btn.classList.toggle("d-none", !hasSpirits)
      if (val === "wine") btn.classList.toggle("d-none", !hasWine)
    })
  }

  // Hide wine color buttons with zero matching wines
  _filterWineColorButtons(wineColors) {
    // Find the wine color step (step 4, first wine flow step)
    const wineColorStep = this.stepTargets.find(el =>
      el.dataset.flow === "wine" && el.querySelector("[data-action*='setWineColor']")
    )
    if (!wineColorStep) return
    const buttons = wineColorStep.querySelectorAll(".sommelier-option-btn")
    buttons.forEach(btn => {
      const color = btn.dataset.value
      if (!color || color === "no_preference") return // always show "Surprise me"
      const count = wineColors[color] || 0
      btn.classList.toggle("d-none", count === 0)
    })
  }

  // === SPIRITS FLOW ===

  setSmoky(event) {
    this.preferences.smoky = event.currentTarget.dataset.value === "true"
    this._advanceFlow()
  }

  setTaste(event) {
    this.preferences.taste = event.currentTarget.dataset.value
    this._advanceFlow()
  }

  setBudget(event) {
    this.preferences.budget = parseInt(event.currentTarget.dataset.value, 10)
    this._advanceFlow()
  }

  // === WINE FLOW ===

  setWineColor(event) {
    this.winePreferences.wine_color = event.currentTarget.dataset.value
    this._advanceFlow()
  }

  setWineStyle(event) {
    this.winePreferences.body = event.currentTarget.dataset.body
    this.winePreferences.taste = event.currentTarget.dataset.taste
    this._advanceFlow()
  }

  setWineBudget(event) {
    this.winePreferences.budget = parseInt(event.currentTarget.dataset.value, 10)
    this._advanceFlow()
  }

  // === FLOW NAVIGATION ===

  _spiritsStepIndices() {
    return this.stepTargets
      .map((el, i) => ({ el, i }))
      .filter(({ el }) => el.dataset.flow === "spirits")
      .map(({ i }) => i)
  }

  _wineStepIndices() {
    return this.stepTargets
      .map((el, i) => ({ el, i }))
      .filter(({ el }) => el.dataset.flow === "wine")
      .map(({ i }) => i)
  }

  _advanceFlow() {
    if (this.flowSteps.length === 0) {
      this._fetchResults()
      return
    }
    const nextIdx = this.flowSteps.shift()

    // Auto-skip steps where only one option is visible
    const step = this.stepTargets[nextIdx]
    if (step) {
      const visibleButtons = Array.from(step.querySelectorAll(".sommelier-option-btn"))
        .filter(btn => !btn.classList.contains("d-none"))
      if (visibleButtons.length === 1) {
        visibleButtons[0].click()
        return
      }
    }

    this.showStep(nextIdx)
  }

  showStep(index) {
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("d-none", i !== index)
    })
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")
    if (this.hasFooterTarget) this.footerTarget.classList.add("d-none")
  }

  async _fetchResults() {
    this.stepTargets.forEach(el => el.classList.add("d-none"))
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove("d-none")
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")
    if (this.hasFooterTarget) this.footerTarget.classList.add("d-none")

    const isWine = this.mode === "wine"
    const url = isWine ? this.wineUrlValue : this.urlValue
    const body = isWine ? this.winePreferences : this.preferences

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
        },
        body: JSON.stringify(body),
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.renderResults(data.recommendations, isWine)
    } catch (error) {
      console.error("[Sommelier] Recommendation failed:", error)
      this.renderError()
    } finally {
      if (this.hasLoadingTarget) this.loadingTarget.classList.add("d-none")
    }
  }

  renderResults(recommendations, isWine = false) {
    if (!this.hasResultsTarget) return
    this.resultsTarget.classList.remove("d-none")

    if (!recommendations || recommendations.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="sommelier-empty">
          <p class="sommelier-empty-text">No recommendations found for your preferences. Try different options!</p>
        </div>
      `
      if (this.hasFooterTarget) {
        this.footerTarget.classList.remove("d-none")
        this.footerTarget.innerHTML = `
          <button class="sommelier-btn sommelier-btn-outline" data-action="click->sommelier#restart">Try again</button>
        `
      }
      return
    }

    const title = isWine ? "Your Wine Picks" : "Your Picks"
    const cards = recommendations.map((rec, i) =>
      isWine ? this.buildWineCard(rec, i) : this.buildCard(rec, i)
    ).join("")

    this.resultsTarget.innerHTML = `
      <div class="sommelier-results-header">
        <h3 class="sommelier-results-title">${title}</h3>
        <p class="sommelier-results-subtitle">Based on your preferences</p>
      </div>
      <div class="sommelier-cards">${cards}</div>
    `

    if (this.hasFooterTarget) {
      this.footerTarget.classList.remove("d-none")
      this.footerTarget.innerHTML = `
        <button class="sommelier-btn sommelier-btn-outline" data-action="click->sommelier#restart">
          Try different preferences
        </button>
      `
    }
  }

  buildCard(rec, index) {
    const medal = index === 0 ? "🥇" : index === 1 ? "🥈" : "🥉"
    const tags = (rec.tags || []).map(t =>
      `<span class="sommelier-tag">${t.replace(/_/g, " ")}</span>`
    ).join("")

    const tasting = rec.tasting_notes
      ? `<div class="sommelier-tasting">
           ${rec.tasting_notes.nose ? `<div><strong>Nose:</strong> ${rec.tasting_notes.nose}</div>` : ""}
           ${rec.tasting_notes.palate ? `<div><strong>Palate:</strong> ${rec.tasting_notes.palate}</div>` : ""}
           ${rec.tasting_notes.finish ? `<div><strong>Finish:</strong> ${rec.tasting_notes.finish}</div>` : ""}
         </div>`
      : ""

    const pairing = rec.best_pairing
      ? `<div class="sommelier-pairing">
           <span class="sommelier-pairing-label">Pairs with:</span>
           <span class="sommelier-pairing-food">${rec.best_pairing.food_name}</span>
         </div>`
      : ""

    const story = rec.story
      ? `<p class="sommelier-story">${rec.story}</p>`
      : ""

    const region = rec.region
      ? `<span class="sommelier-region">${rec.region}</span>`
      : ""

    return `
      <div class="sommelier-card" data-menuitem-id="${rec.id}">
        <div class="sommelier-card-header">
          <span class="sommelier-medal">${medal}</span>
          <div class="sommelier-card-title-wrap">
            <h4 class="sommelier-card-title">${rec.name}</h4>
            ${region}
          </div>
          <span class="sommelier-card-price">${rec.price ? this.formatPrice(rec.price) : ""}</span>
        </div>
        ${rec.description ? `<p class="sommelier-card-desc">${rec.description}</p>` : ""}
        <div class="sommelier-tags">${tags}</div>
        ${tasting}
        ${story}
        ${pairing}
        <div class="sommelier-card-footer">
          <span class="sommelier-match-score">${rec.score}% match</span>
          ${rec.has_pairings ? `<button class="sommelier-btn sommelier-btn-sm"
                  data-action="click->sommelier#showPairings"
                  data-menuitem-id="${rec.id}">
            View pairings
          </button>` : ""}
        </div>
      </div>
    `
  }

  buildWineCard(rec, index) {
    const medal = index === 0 ? "🥇" : index === 1 ? "🥈" : "🥉"
    const tags = (rec.tags || []).map(t =>
      `<span class="sommelier-tag">${t.replace(/_/g, " ")}</span>`
    ).join("")

    // Wine-specific metadata line
    const wineMeta = []
    if (rec.wine_color) wineMeta.push(rec.wine_color.charAt(0).toUpperCase() + rec.wine_color.slice(1))
    if (rec.grape_variety) wineMeta.push(rec.grape_variety)
    if (rec.appellation) wineMeta.push(rec.appellation)
    if (rec.vintage_year) wineMeta.push(rec.vintage_year)
    if (rec.classification) wineMeta.push(rec.classification)
    const wineMetaHtml = wineMeta.length > 0
      ? `<div class="sommelier-wine-meta">${wineMeta.join(" · ")}</div>`
      : ""

    const pairing = rec.best_pairing
      ? `<div class="sommelier-pairing">
           <span class="sommelier-pairing-label">Pairs with:</span>
           <span class="sommelier-pairing-food">${rec.best_pairing.food_name}</span>
         </div>`
      : ""

    const story = rec.story
      ? `<p class="sommelier-story">${rec.story}</p>`
      : ""

    return `
      <div class="sommelier-card sommelier-card-wine" data-menuitem-id="${rec.id}">
        <div class="sommelier-card-header">
          <span class="sommelier-medal">${medal}</span>
          <div class="sommelier-card-title-wrap">
            <h4 class="sommelier-card-title">${rec.name}</h4>
            ${wineMetaHtml}
          </div>
          <span class="sommelier-card-price">${rec.price ? this.formatPrice(rec.price) : ""}</span>
        </div>
        ${rec.description ? `<p class="sommelier-card-desc">${rec.description}</p>` : ""}
        <div class="sommelier-tags">${tags}</div>
        ${story}
        ${pairing}
        <div class="sommelier-card-footer">
          <span class="sommelier-match-score">${rec.score}% match</span>
          ${rec.has_pairings ? `<button class="sommelier-btn sommelier-btn-sm"
                  data-action="click->sommelier#showPairings"
                  data-menuitem-id="${rec.id}">
            View pairings
          </button>` : ""}
        </div>
      </div>
    `
  }

  async showPairings(event) {
    const itemId = event.currentTarget.dataset.menuitemId
    const url = this.pairingsUrlValue.replace(":menuitem_id", itemId)

    try {
      const response = await fetch(url, {
        headers: { "Accept": "application/json" },
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.renderPairingsModal(data)
    } catch (error) {
      console.error("[Sommelier] Pairings fetch failed:", error)
    }
  }

  renderPairingsModal(data) {
    const existing = document.getElementById("sommelier-pairings-modal")
    if (existing) existing.remove()

    const pairingsHtml = (data.pairings || []).map(p => `
      <div class="sommelier-pairing-card">
        <div class="sommelier-pairing-card-header">
          <h5>${p.food_name}</h5>
          <span class="sommelier-match-score">${p.score}%</span>
        </div>
        ${p.food_description ? `<p class="sommelier-pairing-desc">${p.food_description}</p>` : ""}
        ${p.food_price ? `<span class="sommelier-pairing-price">${this.formatPrice(p.food_price)}</span>` : ""}
        <p class="sommelier-pairing-rationale">${p.rationale || ""}</p>
        ${p.pairing_type === "surprise" ? '<span class="sommelier-badge-surprise">Surprise pick</span>' : ""}
      </div>
    `).join("")

    const similarHtml = (data.similar || []).filter(s => s.on_menu).map(s => `
      <div class="sommelier-similar-card">
        <h5>${s.menuitem_name || s.product_name}</h5>
        <span class="sommelier-match-score">${s.score}% similar</span>
        ${s.menuitem_price ? `<span class="sommelier-pairing-price">${this.formatPrice(s.menuitem_price)}</span>` : ""}
        <p class="sommelier-similar-rationale">${s.rationale || ""}</p>
      </div>
    `).join("")

    const modal = document.createElement("div")
    modal.id = "sommelier-pairings-modal"
    modal.className = "sommelier-modal-overlay"
    modal.innerHTML = `
      <div class="sommelier-modal">
        <div class="sommelier-modal-header">
          <h3>Pairings for ${data.drink.name}</h3>
          <button class="sommelier-modal-close" id="sommelier-pairings-close-btn">✕</button>
        </div>
        <div class="sommelier-modal-body">
          ${pairingsHtml.length > 0 ? `<h4>Food pairings</h4>${pairingsHtml}` : "<p>No pairings available yet.</p>"}
          ${similarHtml.length > 0 ? `<h4 class="mt-3">You might also like</h4>${similarHtml}` : ""}
        </div>
      </div>
    `
    document.body.appendChild(modal)

    // Wire close handlers directly (modal is outside Stimulus scope)
    modal.querySelector("#sommelier-pairings-close-btn").addEventListener("click", () => this.closePairingsModal())
    modal.addEventListener("click", (e) => { if (e.target === modal) this.closePairingsModal() })
  }

  closePairingsModal() {
    const modal = document.getElementById("sommelier-pairings-modal")
    if (modal) modal.remove()
  }

  renderError() {
    if (!this.hasResultsTarget) return
    this.resultsTarget.classList.remove("d-none")
    this.resultsTarget.innerHTML = `
      <div class="sommelier-empty">
        <p class="sommelier-empty-text">Something went wrong. Please try again.</p>
      </div>
    `
    if (this.hasFooterTarget) {
      this.footerTarget.classList.remove("d-none")
      this.footerTarget.innerHTML = `
        <button class="sommelier-btn sommelier-btn-outline" data-action="click->sommelier#restart">Retry</button>
      `
    }
  }

  restart() {
    this.open()
  }

  formatPrice(price) {
    if (!price) return ""
    try {
      return parseFloat(price).toLocaleString(undefined, {
        style: "currency",
        currency: this.currencyValue,
        minimumFractionDigits: 2,
      })
    } catch {
      return `${parseFloat(price).toFixed(2)} ${this.currencyValue}`
    }
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
