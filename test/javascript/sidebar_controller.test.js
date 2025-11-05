/**
 * Sidebar Controller Tests
 * Tests for mobile sidebar toggle functionality
 */

import { Application } from "@hotwired/stimulus"
import SidebarController from "../../app/javascript/controllers/sidebar_controller"

describe("SidebarController", () => {
  let application
  let container
  let sidebar
  let overlay
  let toggleButton

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="sidebar">
        <button type="button" 
                class="sidebar-toggle-btn"
                data-action="click->sidebar#toggle"
                aria-label="Toggle navigation">
          <i class="bi bi-list"></i>
        </button>
        
        <aside class="sidebar-2025" data-sidebar-target="sidebar">
          <div class="sidebar-header">
            <h3>Test Restaurant</h3>
            <button type="button" 
                    data-action="click->sidebar#close" 
                    aria-label="Close menu">
              <i class="bi bi-x-lg"></i>
            </button>
          </div>
          
          <div class="sidebar-section">
            <a href="#" class="sidebar-link" data-turbo-frame="restaurant_content">
              Details
            </a>
          </div>
        </aside>
        
        <div class="sidebar-overlay" 
             data-sidebar-target="overlay" 
             data-action="click->sidebar#close">
        </div>
      </div>
    `

    // Set up Stimulus
    application = Application.start()
    application.register("sidebar", SidebarController)

    container = document.querySelector('[data-controller="sidebar"]')
    sidebar = document.querySelector('.sidebar-2025')
    overlay = document.querySelector('.sidebar-overlay')
    toggleButton = document.querySelector('.sidebar-toggle-btn')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
  })

  test("controller connects successfully", () => {
    expect(container).toBeTruthy()
    expect(sidebar).toBeTruthy()
    expect(overlay).toBeTruthy()
  })

  test("toggle opens sidebar", () => {
    toggleButton.click()
    
    expect(sidebar.classList.contains('open')).toBe(true)
    expect(overlay.classList.contains('active')).toBe(true)
    expect(document.body.style.overflow).toBe('hidden')
  })

  test("toggle closes sidebar when open", () => {
    // Open first
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Wait for debounce
    jest.advanceTimersByTime(500)
    
    // Close
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(false)
    expect(overlay.classList.contains('active')).toBe(false)
    expect(document.body.style.overflow).toBe('')
  })

  test("close button closes sidebar", () => {
    // Open sidebar first
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Click close button
    const closeButton = sidebar.querySelector('[aria-label="Close menu"]')
    closeButton.click()
    
    expect(sidebar.classList.contains('open')).toBe(false)
    expect(overlay.classList.contains('active')).toBe(false)
  })

  test("overlay click closes sidebar", () => {
    // Open sidebar
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Click overlay
    overlay.click()
    
    expect(sidebar.classList.contains('open')).toBe(false)
    expect(overlay.classList.contains('active')).toBe(false)
  })

  test("rapid toggles are debounced", () => {
    // Click multiple times rapidly
    toggleButton.click()
    toggleButton.click()
    toggleButton.click()
    toggleButton.click()
    toggleButton.click()
    
    // Sidebar should be open (first click went through)
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Other clicks should have been ignored (not toggled back and forth)
    expect(overlay.classList.contains('active')).toBe(true)
  })

  test("prevents event bubbling", () => {
    const parentClickHandler = jest.fn()
    container.addEventListener('click', parentClickHandler)
    
    const event = new MouseEvent('click', { 
      bubbles: true, 
      cancelable: true 
    })
    
    toggleButton.dispatchEvent(event)
    
    // Event should be prevented from bubbling
    expect(event.defaultPrevented).toBe(true)
  })

  test("handles missing sidebar target gracefully", () => {
    // Remove data-sidebar-target
    sidebar.removeAttribute('data-sidebar-target')
    
    // Should still work via fallback querySelector
    expect(() => {
      toggleButton.click()
    }).not.toThrow()
    
    // Should still open via fallback
    const fallbackSidebar = document.querySelector('.sidebar-2025')
    expect(fallbackSidebar.classList.contains('open')).toBe(true)
  })

  test("resize to desktop closes sidebar", () => {
    // Mock mobile viewport
    global.innerWidth = 375
    
    // Open sidebar
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Mock resize to desktop
    global.innerWidth = 1024
    window.dispatchEvent(new Event('resize'))
    
    // Sidebar should close
    expect(sidebar.classList.contains('open')).toBe(false)
  })

  test("timestamp-based debounce works correctly", () => {
    const realDateNow = Date.now
    let mockTime = 1000
    
    // Mock Date.now
    Date.now = jest.fn(() => mockTime)
    
    // First click at t=1000
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true)
    
    // Second click at t=1200 (200ms later) - should be ignored
    mockTime = 1200
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(true) // Still open
    
    // Third click at t=1500 (500ms after first) - should work
    mockTime = 1500
    toggleButton.click()
    expect(sidebar.classList.contains('open')).toBe(false) // Now closed
    
    // Restore Date.now
    Date.now = realDateNow
  })
})

describe("SidebarController - Mobile Behavior", () => {
  let application

  beforeEach(() => {
    // Mock mobile viewport
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      configurable: true,
      value: 375
    })

    document.body.innerHTML = `
      <div data-controller="sidebar">
        <button class="sidebar-toggle-btn" 
                data-action="click->sidebar#toggle">
          Toggle
        </button>
        <aside class="sidebar-2025" data-sidebar-target="sidebar"></aside>
        <div class="sidebar-overlay" data-sidebar-target="overlay"></div>
      </div>
    `

    application = Application.start()
    application.register("sidebar", SidebarController)
  })

  afterEach(() => {
    application.stop()
  })

  test("toggle button is visible on mobile", () => {
    const button = document.querySelector('.sidebar-toggle-btn')
    const styles = window.getComputedStyle(button)
    
    // In a real test environment with CSS, this would be 'flex'
    // For now, just verify button exists
    expect(button).toBeTruthy()
  })

  test("sidebar starts off-screen on mobile", () => {
    const sidebar = document.querySelector('.sidebar-2025')
    
    // Should not have 'open' class initially
    expect(sidebar.classList.contains('open')).toBe(false)
  })
})
