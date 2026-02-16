import { Controller } from "@hotwired/stimulus"

/**
 * Section Tabs Controller
 * Horizontal scrollable tab bar that highlights the active section on scroll.
 * Uses IntersectionObserver for performant scroll tracking.
 *
 * Usage:
 *   <div data-controller="section-tabs">
 *     <nav data-section-tabs-target="tabBar" class="section-tabs">
 *       <!-- tabs auto-generated from sections -->
 *     </nav>
 *     <div data-section-tabs-target="content">
 *       <!-- menu sections with id="menusection_<id>" -->
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["tabBar", "content"]

  connect() {
    this._buildTabs()
    this._setupObserver()
  }

  disconnect() {
    if (this._observer) {
      this._observer.disconnect()
      this._observer = null
    }
  }

  scrollToSection(event) {
    event.preventDefault()
    const sectionId = event.currentTarget.dataset.sectionId
    const el = document.getElementById(sectionId)
    if (!el) return

    // Scroll with offset for sticky header
    const headerOffset = this._getHeaderOffset()
    const y = el.getBoundingClientRect().top + window.pageYOffset - headerOffset
    window.scrollTo({ top: y, behavior: "smooth" })

    // Update active tab immediately
    this._setActiveTab(sectionId)
  }

  // ── Private ──────────────────────────────────────────────────────────

  _buildTabs() {
    if (!this.hasTabBarTarget) return

    const content = this.hasContentTarget ? this.contentTarget : this.element
    const sections = content.querySelectorAll('[id^="menusection_"]')
    if (sections.length < 2) {
      // Don't show tabs for single-section menus
      this.tabBarTarget.classList.add("d-none")
      return
    }

    const fragment = document.createDocumentFragment()

    sections.forEach(sec => {
      // Find the section title — it's a sibling with .h3 or h3
      const titleEl = this._findSectionTitle(sec)
      const title = titleEl ? titleEl.textContent.trim() : sec.id.replace("menusection_", "Section ")

      const tab = document.createElement("button")
      tab.type = "button"
      tab.className = "section-tab"
      tab.textContent = title
      tab.dataset.sectionId = sec.id
      tab.dataset.action = "click->section-tabs#scrollToSection"
      tab.setAttribute("data-testid", `section-tab-${sec.id}`)
      fragment.appendChild(tab)
    })

    this.tabBarTarget.innerHTML = ""
    this.tabBarTarget.appendChild(fragment)
  }

  _findSectionTitle(sectionAnchor) {
    // The title is in a sibling element after the anchor div
    let el = sectionAnchor.nextElementSibling
    while (el) {
      if (el.id && el.id.startsWith("menusection_")) break
      const title = el.querySelector(".h3, h3, .card-title")
      if (title) return title
      el = el.nextElementSibling
    }
    return null
  }

  _setupObserver() {
    if (!this.hasTabBarTarget) return

    const content = this.hasContentTarget ? this.contentTarget : this.element
    const sections = content.querySelectorAll('[id^="menusection_"]')
    if (sections.length < 2) return

    // rootMargin: trigger when section is near top of viewport
    const headerOffset = this._getHeaderOffset()
    this._observer = new IntersectionObserver(
      (entries) => {
        // Find the topmost visible section
        let topEntry = null
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            if (!topEntry || entry.boundingClientRect.top < topEntry.boundingClientRect.top) {
              topEntry = entry
            }
          }
        })
        if (topEntry) {
          this._setActiveTab(topEntry.target.id)
        }
      },
      {
        rootMargin: `-${headerOffset}px 0px -70% 0px`,
        threshold: 0
      }
    )

    sections.forEach(sec => this._observer.observe(sec))
  }

  _setActiveTab(sectionId) {
    if (!this.hasTabBarTarget) return

    const tabs = this.tabBarTarget.querySelectorAll(".section-tab")
    tabs.forEach(tab => {
      const isActive = tab.dataset.sectionId === sectionId
      tab.classList.toggle("active", isActive)
      if (isActive) {
        // Scroll tab into view within the tab bar
        tab.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
      }
    })
  }

  _getHeaderOffset() {
    // Account for sticky header height
    const header = document.querySelector(".menu-sticky-header")
    return header ? header.offsetHeight + 8 : 60
  }
}
