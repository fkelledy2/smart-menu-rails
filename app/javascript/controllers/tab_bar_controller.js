import { Controller } from "@hotwired/stimulus"

/**
 * Tab Bar Stimulus Controller
 * Horizontal scrollable tab bar for mobile navigation.
 * Highlights the active tab and scrolls it into view.
 * Integrates with Turbo Frames for content switching.
 *
 * Usage:
 * <nav data-controller="tab-bar"
 *      data-tab-bar-active-class-value="tab-bar__tab--active"
 *      data-tab-bar-frame-value="content-frame">
 *   <div data-tab-bar-target="scroll" class="tab-bar__scroll">
 *     <a data-tab-bar-target="tab"
 *        data-action="click->tab-bar#select"
 *        data-tab-bar-section-param="details"
 *        href="/restaurants/1/sections/details">
 *       Details
 *     </a>
 *     <a data-tab-bar-target="tab" ...>Hours</a>
 *   </div>
 *   <div data-tab-bar-target="indicator" class="tab-bar__indicator"></div>
 * </nav>
 */
export default class extends Controller {
  static targets = ["tab", "scroll", "indicator"]

  static values = {
    activeClass: { type: String, default: "tab-bar__tab--active" },
    frame:       String  // optional Turbo Frame id to target
  }

  connect() {
    // Activate the first tab by default if none is active
    const activeTab = this.tabTargets.find(t => t.classList.contains(this.activeClassValue))
    if (!activeTab && this.tabTargets.length > 0) {
      this.activate(this.tabTargets[0])
    } else if (activeTab) {
      this.scrollIntoView(activeTab)
      this.moveIndicator(activeTab)
    }

    console.log("[TabBar] connected", { tabs: this.tabTargets.length })
  }

  // --- Actions ---

  select(event) {
    const tab = event.currentTarget
    this.activate(tab)

    // If linked to a Turbo Frame, update its src
    if (this.hasFrameValue && tab.dataset.tabBarSectionParam) {
      const frame = document.getElementById(this.frameValue)
      if (frame && tab.href) {
        frame.src = tab.href
        event.preventDefault()
      }
    }
  }

  // Programmatic activation by section name
  activateSection(sectionName) {
    const tab = this.tabTargets.find(t => t.dataset.tabBarSectionParam === sectionName)
    if (tab) this.activate(tab)
  }

  // --- Internal ---

  activate(tab) {
    // Deactivate all
    this.tabTargets.forEach(t => {
      t.classList.remove(this.activeClassValue)
      t.setAttribute("aria-selected", "false")
    })

    // Activate selected
    tab.classList.add(this.activeClassValue)
    tab.setAttribute("aria-selected", "true")

    this.scrollIntoView(tab)
    this.moveIndicator(tab)

    this.dispatch("changed", {
      detail: { section: tab.dataset.tabBarSectionParam || tab.textContent.trim() }
    })
  }

  scrollIntoView(tab) {
    if (!this.hasScrollTarget) return

    const container = this.scrollTarget
    const tabLeft = tab.offsetLeft
    const tabWidth = tab.offsetWidth
    const containerWidth = container.offsetWidth
    const scrollLeft = container.scrollLeft

    // Center the tab in the scroll container
    const targetScroll = tabLeft - (containerWidth / 2) + (tabWidth / 2)

    container.scrollTo({
      left: Math.max(0, targetScroll),
      behavior: "smooth"
    })
  }

  moveIndicator(tab) {
    if (!this.hasIndicatorTarget) return

    const indicator = this.indicatorTarget
    indicator.style.width = `${tab.offsetWidth}px`
    indicator.style.transform = `translateX(${tab.offsetLeft}px)`
  }
}
