import { Controller } from "@hotwired/stimulus"

/**
 * Scrollspy Stimulus Controller
 * Highlights the active section tab as the user scrolls through menu sections.
 * Uses IntersectionObserver for efficient, jank-free tracking.
 *
 * Usage:
 * <div data-controller="scrollspy" data-scrollspy-offset-value="200">
 *   <nav data-scrollspy-target="nav">
 *     <a class="section-tab" href="#section_1">Section 1</a>
 *   </nav>
 *   <!-- sections with id="section_1" etc. elsewhere on page -->
 * </div>
 */
export default class extends Controller {
  static targets = ["nav"]
  static values = {
    offset: { type: Number, default: 180 }
  }

  connect() {
    this.observer = null
    this.visibleSections = new Map()
    this.initObserver()
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  initObserver() {
    const links = this.navTarget.querySelectorAll("a[href^='#']")
    if (!links.length) return

    const sectionIds = Array.from(links).map(a => a.getAttribute("href").replace("#", "")).filter(Boolean)
    const sections = sectionIds.map(id => document.getElementById(id)).filter(Boolean)
    if (!sections.length) return

    // rootMargin: negative top margin = header height, so "in view" means below the sticky header
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.visibleSections.set(entry.target.id, entry.intersectionRatio)
          } else {
            this.visibleSections.delete(entry.target.id)
          }
        })
        this.updateActive()
      },
      {
        rootMargin: `-${this.offsetValue}px 0px -40% 0px`,
        threshold: [0, 0.1, 0.5]
      }
    )

    sections.forEach(s => this.observer.observe(s))
  }

  updateActive() {
    if (this.visibleSections.size === 0) return

    // Pick the first visible section (highest on page)
    const links = Array.from(this.navTarget.querySelectorAll("a[href^='#']"))
    let activeLink = null

    for (const link of links) {
      const id = link.getAttribute("href").replace("#", "")
      if (this.visibleSections.has(id)) {
        activeLink = link
        break
      }
    }

    if (!activeLink) return

    links.forEach(l => l.classList.remove("active"))
    activeLink.classList.add("active")

    // Scroll the tab into view if it's off-screen in the horizontal scroll container
    const container = activeLink.closest(".sections-tabs-container")
    if (container) {
      const linkRect = activeLink.getBoundingClientRect()
      const containerRect = container.getBoundingClientRect()
      if (linkRect.left < containerRect.left || linkRect.right > containerRect.right) {
        activeLink.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" })
      }
    }
  }
}
