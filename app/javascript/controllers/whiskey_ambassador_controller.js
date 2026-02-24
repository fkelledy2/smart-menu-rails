import { Controller } from "@hotwired/stimulus"

/**
 * Whiskey Ambassador Controller — Guest-facing whiskey exploration.
 *
 * Two modes:
 *   - Quick Pick: experience → region → flavor → budget → /recommend_whiskey
 *   - Explore:    browse by cluster/region/filters → /explore_whiskeys
 *
 * Session memory: tracks shown items to avoid repeats on "Show me more".
 *
 * Targets:
 *   panel, step, results, loading, explore, flightsContainer, badge
 */
export default class extends Controller {
  static targets = ["panel", "step", "results", "loading", "explore", "flightsContainer", "badge"]
  static values = {
    recommendUrl: String,
    exploreUrl: String,
    flightsUrl: String,
    currency: { type: String, default: "EUR" },
  }

  connect() {
    this.preferences = {}
    this.shownIds = JSON.parse(sessionStorage.getItem("wa_shown_ids") || "[]")
    this.myPicks = JSON.parse(sessionStorage.getItem("wa_my_picks") || "[]")
    this._updateBadge()
  }

  // ── Panel ────────────────────────────────────────────────────

  open() {
    this.preferences = { experience_level: null, region_pref: null, flavor_pref: null, budget: null }
    this.currentStepIdx = 0
    this.showStep(0)
    this.panelTarget.classList.remove("d-none")
    this.panelTarget.classList.add("wa-open")
    document.body.classList.add("wa-active")
  }

  close() {
    this.panelTarget.classList.add("d-none")
    this.panelTarget.classList.remove("wa-open")
    document.body.classList.remove("wa-active")
  }

  // ── Quick Pick Flow ──────────────────────────────────────────

  setExperience(event) {
    this.preferences.experience_level = event.currentTarget.dataset.value
    this._nextStep()
  }

  setRegion(event) {
    this.preferences.region_pref = event.currentTarget.dataset.value
    this._nextStep()
  }

  setFlavor(event) {
    this.preferences.flavor_pref = event.currentTarget.dataset.value
    this._nextStep()
  }

  setBudget(event) {
    this.preferences.budget = parseInt(event.currentTarget.dataset.value, 10)
    this._fetchRecommendations()
  }

  _nextStep() {
    this.currentStepIdx++
    this.showStep(this.currentStepIdx)
  }

  showStep(index) {
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("d-none", i !== index)
    })
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")
    if (this.hasExploreTarget) this.exploreTarget.classList.add("d-none")
  }

  // ── Fetch Recommendations ────────────────────────────────────

  async _fetchRecommendations() {
    this.stepTargets.forEach(el => el.classList.add("d-none"))
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove("d-none")
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")

    try {
      const response = await fetch(this.recommendUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this._csrfToken,
        },
        body: JSON.stringify({
          ...this.preferences,
          exclude_ids: this.shownIds,
        }),
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      const newIds = data.recommendations.map(r => r.menuitem_id)
      this.shownIds = [...new Set([...this.shownIds, ...newIds])]
      sessionStorage.setItem("wa_shown_ids", JSON.stringify(this.shownIds))

      this._renderRecommendations(data.recommendations)
    } catch (error) {
      console.error("[WhiskeyAmbassador] Recommendation failed:", error)
      this._renderError()
    } finally {
      if (this.hasLoadingTarget) this.loadingTarget.classList.add("d-none")
    }
  }

  // ── Explore Mode ─────────────────────────────────────────────

  openExplore() {
    this.stepTargets.forEach(el => el.classList.add("d-none"))
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")
    if (this.hasExploreTarget) this.exploreTarget.classList.remove("d-none")
    this.panelTarget.classList.remove("d-none")
    this.panelTarget.classList.add("wa-open")
    document.body.classList.add("wa-active")
    this._fetchExplore()
  }

  async filterExplore(event) {
    const cluster = event.currentTarget.dataset.cluster || ""
    const region = event.currentTarget.dataset.region || ""
    await this._fetchExplore({ cluster, region })
  }

  async _fetchExplore(filters = {}) {
    if (!this.hasExploreTarget) return

    const params = new URLSearchParams()
    if (filters.cluster) params.set("cluster", filters.cluster)
    if (filters.region) params.set("region", filters.region)
    if (filters.age_range) params.set("age_range", filters.age_range)
    if (filters.price_range) params.set("price_range", filters.price_range)
    if (filters.new_only) params.set("new_only", "true")
    if (filters.rare_only) params.set("rare_only", "true")

    const url = `${this.exploreUrlValue}?${params.toString()}`

    try {
      const response = await fetch(url, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this._renderExplore(data)
    } catch (error) {
      console.error("[WhiskeyAmbassador] Explore failed:", error)
    }
  }

  // ── Flights ──────────────────────────────────────────────────

  async showFlights() {
    if (!this.hasFlightsContainerTarget) return

    this.stepTargets.forEach(el => el.classList.add("d-none"))
    if (this.hasResultsTarget) this.resultsTarget.classList.add("d-none")
    if (this.hasExploreTarget) this.exploreTarget.classList.add("d-none")
    this.flightsContainerTarget.classList.remove("d-none")
    this.panelTarget.classList.remove("d-none")
    this.panelTarget.classList.add("wa-open")

    try {
      const response = await fetch(this.flightsUrlValue, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this._renderFlights(data.flights)
    } catch (error) {
      console.error("[WhiskeyAmbassador] Flights fetch failed:", error)
    }
  }

  // ── My Picks (Session Memory) ────────────────────────────────

  addToPicks(event) {
    const id = parseInt(event.currentTarget.dataset.menuitemId, 10)
    const name = event.currentTarget.dataset.name || ""
    const price = event.currentTarget.dataset.price || ""

    if (!this.myPicks.find(p => p.id === id)) {
      this.myPicks.push({ id, name, price })
      sessionStorage.setItem("wa_my_picks", JSON.stringify(this.myPicks))
    }

    event.currentTarget.textContent = "Added ✓"
    event.currentTarget.disabled = true
    this._updateBadge()
  }

  showMyPicks() {
    if (!this.hasResultsTarget) return

    this.stepTargets.forEach(el => el.classList.add("d-none"))
    if (this.hasExploreTarget) this.exploreTarget.classList.add("d-none")
    if (this.hasFlightsContainerTarget) this.flightsContainerTarget.classList.add("d-none")
    this.resultsTarget.classList.remove("d-none")
    this.panelTarget.classList.remove("d-none")
    this.panelTarget.classList.add("wa-open")

    if (this.myPicks.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="wa-empty">
          <p>No picks yet. Explore our whiskey collection to find your favourites!</p>
          <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#open">Start exploring</button>
        </div>
      `
      return
    }

    const cards = this.myPicks.map(pick => `
      <div class="wa-pick-card">
        <span class="wa-pick-name">${pick.name}</span>
        ${pick.price ? `<span class="wa-pick-price">${this.formatPrice(pick.price)}</span>` : ""}
      </div>
    `).join("")

    this.resultsTarget.innerHTML = `
      <div class="wa-results-header">
        <h3 class="wa-results-title">My Whiskey Picks</h3>
        <p class="wa-results-subtitle">${this.myPicks.length} dram${this.myPicks.length === 1 ? "" : "s"} saved</p>
      </div>
      <div class="wa-picks-list">${cards}</div>
      <div class="wa-actions">
        <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#clearPicks">Clear all</button>
      </div>
    `
  }

  clearPicks() {
    this.myPicks = []
    sessionStorage.removeItem("wa_my_picks")
    this._updateBadge()
    this.showMyPicks()
  }

  // ── Render Helpers ───────────────────────────────────────────

  _renderRecommendations(recs) {
    if (!this.hasResultsTarget) return
    this.resultsTarget.classList.remove("d-none")

    if (!recs || recs.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="wa-empty">
          <p>No matches found. Try different preferences!</p>
          <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#restart">Try again</button>
        </div>
      `
      return
    }

    const cards = recs.map((rec, i) => this._buildWhiskeyCard(rec, i)).join("")

    this.resultsTarget.innerHTML = `
      <div class="wa-results-header">
        <h3 class="wa-results-title">Your Whiskey Picks</h3>
        <p class="wa-results-subtitle">Curated for your palate</p>
      </div>
      <div class="wa-cards">${cards}</div>
      <div class="wa-actions">
        <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#showMore">Show me more</button>
        <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#restart">Start over</button>
      </div>
    `
  }

  _buildWhiskeyCard(rec, index) {
    const medal = index === 0 ? "🥇" : index === 1 ? "🥈" : "🥉"
    const tags = (rec.tags || []).map(t =>
      `<span class="wa-tag">${t.replace(/_/g, " ")}</span>`
    ).join("")

    const meta = []
    if (rec.distillery) meta.push(rec.distillery)
    if (rec.region) meta.push(rec.region.replace(/_/g, " "))
    if (rec.age_years) meta.push(`${rec.age_years}yo`)
    if (rec.abv) meta.push(`${rec.abv}%`)
    const metaHtml = meta.length > 0 ? `<div class="wa-meta">${meta.join(" · ")}</div>` : ""

    const badges = []
    if (rec.staff_pick) badges.push('<span class="wa-badge wa-badge-pick">Staff Pick</span>')
    if (rec.new_arrival) badges.push('<span class="wa-badge wa-badge-new">New</span>')
    if (rec.rare) badges.push('<span class="wa-badge wa-badge-rare">Rare</span>')
    const badgesHtml = badges.length > 0 ? `<div class="wa-badges">${badges.join("")}</div>` : ""

    const inPicks = this.myPicks.find(p => p.id === rec.menuitem_id)

    return `
      <div class="wa-card" data-menuitem-id="${rec.menuitem_id}">
        <div class="wa-card-header">
          <span class="wa-medal">${medal}</span>
          <div class="wa-card-title-wrap">
            <h4 class="wa-card-title">${rec.name}</h4>
            ${metaHtml}
          </div>
          <span class="wa-card-price">${rec.price ? this.formatPrice(rec.price) : ""}</span>
        </div>
        ${badgesHtml}
        <div class="wa-tags">${tags}</div>
        ${rec.staff_tasting_note ? `<p class="wa-tasting-note">"${rec.staff_tasting_note}"</p>` : ""}
        ${rec.why_text ? `<p class="wa-why-text">${rec.why_text}</p>` : ""}
        <div class="wa-card-footer">
          <span class="wa-match-score">${Math.round(rec.score * 100)}% match</span>
          <button class="wa-btn wa-btn-sm"
                  data-action="click->whiskey-ambassador#addToPicks"
                  data-menuitem-id="${rec.menuitem_id}"
                  data-name="${rec.name}"
                  data-price="${rec.price || ""}"
                  ${inPicks ? 'disabled' : ''}>
            ${inPicks ? "Added ✓" : "Add to My Picks"}
          </button>
        </div>
      </div>
    `
  }

  _renderExplore(data) {
    if (!this.hasExploreTarget) return

    const quadrants = Object.entries(data.quadrants || {}).map(([key, q]) => `
      <button class="wa-quadrant ${q.count === 0 ? 'wa-quadrant-empty' : ''}"
              data-action="click->whiskey-ambassador#filterExplore"
              data-cluster="${key}">
        <span class="wa-quadrant-label">${q.label}</span>
        <span class="wa-quadrant-count">${q.count}</span>
      </button>
    `).join("")

    const items = (data.items || []).map(item => `
      <div class="wa-explore-item">
        <div class="wa-explore-item-header">
          <h5>${item.name}</h5>
          <span class="wa-card-price">${item.price ? this.formatPrice(item.price) : ""}</span>
        </div>
        <div class="wa-explore-meta">
          ${item.distillery ? `<span>${item.distillery}</span>` : ""}
          ${item.region ? `<span>${item.region.replace(/_/g, " ")}</span>` : ""}
          ${item.age_years ? `<span>${item.age_years}yo</span>` : ""}
        </div>
        <div class="wa-tags">${(item.tags || []).map(t => `<span class="wa-tag">${t.replace(/_/g, " ")}</span>`).join("")}</div>
        ${item.staff_pick ? '<span class="wa-badge wa-badge-pick">Staff Pick</span>' : ""}
        ${item.new_arrival ? '<span class="wa-badge wa-badge-new">New</span>' : ""}
        ${item.rare ? '<span class="wa-badge wa-badge-rare">Rare</span>' : ""}
      </div>
    `).join("")

    this.exploreTarget.innerHTML = `
      <div class="wa-explore-header">
        <h3>Explore Our Whiskey Collection</h3>
        <p>Tap a flavor profile to filter</p>
      </div>
      <div class="wa-quadrants">${quadrants}</div>
      <div class="wa-explore-items">${items.length > 0 ? items : "<p class='wa-empty'>No whiskeys match this filter.</p>"}</div>
      <div class="wa-actions">
        <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#_fetchExplore">Show all</button>
      </div>
    `
  }

  _renderFlights(flights) {
    if (!this.hasFlightsContainerTarget) return

    if (!flights || flights.length === 0) {
      this.flightsContainerTarget.innerHTML = `
        <div class="wa-empty"><p>No whiskey flights available right now.</p></div>
      `
      return
    }

    const cards = flights.map(flight => `
      <div class="wa-flight-card">
        <h4 class="wa-flight-title">${flight.title}</h4>
        <p class="wa-flight-narrative">${flight.narrative || ""}</p>
        <div class="wa-flight-meta">
          <span class="wa-flight-price">${flight.display_price ? this.formatPrice(flight.display_price) : ""}</span>
          ${flight.savings ? `<span class="wa-flight-savings">Save ${this.formatPrice(flight.savings)}</span>` : ""}
          ${flight.per_dram_price ? `<span class="wa-flight-per-dram">${this.formatPrice(flight.per_dram_price)}/dram</span>` : ""}
        </div>
        <div class="wa-flight-items">
          ${(flight.items || []).map((item, i) => `
            <div class="wa-flight-item">
              <span class="wa-flight-item-pos">${i + 1}.</span>
              <span class="wa-flight-item-note">${item.note || ""}</span>
            </div>
          `).join("")}
        </div>
      </div>
    `).join("")

    this.flightsContainerTarget.innerHTML = `
      <div class="wa-flights-header">
        <h3>Whiskey Flights</h3>
        <p>Curated tasting experiences</p>
      </div>
      <div class="wa-flights-list">${cards}</div>
    `
  }

  _renderError() {
    if (!this.hasResultsTarget) return
    this.resultsTarget.classList.remove("d-none")
    this.resultsTarget.innerHTML = `
      <div class="wa-empty">
        <p>Something went wrong. Please try again.</p>
        <button class="wa-btn wa-btn-outline" data-action="click->whiskey-ambassador#restart">Retry</button>
      </div>
    `
  }

  _updateBadge() {
    if (this.hasBadgeTarget) {
      const count = this.myPicks.length
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.toggle("d-none", count === 0)
    }
  }

  showMore() {
    this._fetchRecommendations()
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

  get _csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
