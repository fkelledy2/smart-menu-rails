import { Controller } from "@hotwired/stimulus"

// Sidebar navigation controller
// Handles mobile menu toggle and responsive behavior
export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    console.log("[Sidebar] Controller connected")
    this.isToggling = false // Prevent rapid toggle spam
    this.lastToggleTime = 0 // Track last toggle timestamp
    this.setupResponsive()
    this.setupTurboFrameListener()
  }

  disconnect() {
    this.removeResponsive()
    this.removeTurboFrameListener()
  }

  // Open sidebar (mobile)
  open() {
    console.log("[Sidebar] Opening sidebar")
    
    // Fallback: try to find sidebar by class if target not found
    const sidebar = this.hasSidebarTarget 
      ? this.sidebarTarget 
      : document.querySelector('.sidebar-2025')
    
    const overlay = this.hasOverlayTarget 
      ? this.overlayTarget 
      : document.querySelector('.sidebar-overlay')
    
    console.log("[Sidebar] Open - Sidebar element:", sidebar)
    console.log("[Sidebar] Open - Overlay element:", overlay)
    
    if (sidebar) {
      sidebar.classList.add('open')
      console.log("[Sidebar] Added 'open' class to sidebar")
    }
    if (overlay) {
      overlay.classList.add('active')
      console.log("[Sidebar] Added 'active' class to overlay")
    }
    
    // Prevent body scroll when sidebar is open
    document.body.style.overflow = 'hidden'
  }

  // Close sidebar (mobile)
  close() {
    console.log("[Sidebar] Closing sidebar")
    
    // Fallback: try to find sidebar by class if target not found
    const sidebar = this.hasSidebarTarget 
      ? this.sidebarTarget 
      : document.querySelector('.sidebar-2025')
    
    const overlay = this.hasOverlayTarget 
      ? this.overlayTarget 
      : document.querySelector('.sidebar-overlay')
    
    if (sidebar) {
      sidebar.classList.remove('open')
    }
    if (overlay) {
      overlay.classList.remove('active')
    }
    
    // Restore body scroll
    document.body.style.overflow = ''
  }

  // Toggle sidebar (mobile)
  toggle(event) {
    // Prevent event bubbling and multiple calls
    if (event) {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation() // Also prevent other handlers on same element
    }
    
    // AGGRESSIVE DEBOUNCE: Ignore calls within 400ms of last toggle
    const now = Date.now()
    const timeSinceLastToggle = now - this.lastToggleTime
    
    if (timeSinceLastToggle < 400) {
      console.log(`[Sidebar] Ignoring rapid toggle (${timeSinceLastToggle}ms since last toggle)`)
      return
    }
    
    this.lastToggleTime = now
    
    console.log("[Sidebar] Toggle called")
    console.log("[Sidebar] Has sidebar target?", this.hasSidebarTarget)
    
    // Fallback: try to find sidebar by class if target not found
    const sidebar = this.hasSidebarTarget 
      ? this.sidebarTarget 
      : document.querySelector('.sidebar-2025')
    
    console.log("[Sidebar] Sidebar element:", sidebar)
    
    if (sidebar && sidebar.classList.contains('open')) {
      this.close()
    } else {
      this.open()
    }
  }

  // Setup responsive behavior
  setupResponsive() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)
    this.handleResize() // Initial check
  }

  // Remove responsive listeners
  removeResponsive() {
    window.removeEventListener('resize', this.handleResize)
  }

  // Handle window resize
  handleResize() {
    // Close sidebar on desktop resize
    if (window.innerWidth > 768) {
      this.close()
    }
  }

  // Handle navigation link clicks (close sidebar on mobile after selection)
  handleLinkClick(event) {
    // On mobile, close sidebar after clicking a link
    if (window.innerWidth <= 768) {
      // Small delay to allow navigation to start
      setTimeout(() => {
        this.close()
      }, 100)
    }
  }

  // Setup Turbo Frame listener to update active sidebar state
  setupTurboFrameListener() {
    this.updateActiveState = this.updateActiveState.bind(this)
    document.addEventListener('turbo:frame-load', this.updateActiveState)
    // Also update on initial load
    this.updateActiveState()
  }

  // Remove Turbo Frame listener
  removeTurboFrameListener() {
    if (this.updateActiveState) {
      document.removeEventListener('turbo:frame-load', this.updateActiveState)
    }
  }

  // Update active state based on current URL
  updateActiveState() {
    const url = new URL(window.location.href)
    const section = url.searchParams.get('section') || 'details'
    const hash = window.location.hash
    
    console.log("[Sidebar] Updating active state for section:", section)
    
    // Find all sidebar links
    const sidebarLinks = this.element.querySelectorAll('.sidebar-link')
    
    sidebarLinks.forEach(link => {
      const linkUrl = new URL(link.href)
      const linkSection = linkUrl.searchParams.get('section') || 'details'
      
      if (linkSection === section) {
        link.classList.add('active')
      } else {
        link.classList.remove('active')
      }
    })

    if (hash && hash.length > 1) {
      const targetId = hash.slice(1)
      const target = document.getElementById(targetId)
      if (target) {
        setTimeout(() => {
          try {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' })
          } catch (e) {
            target.scrollIntoView()
          }
        }, 0)
      }
    }
  }
}
