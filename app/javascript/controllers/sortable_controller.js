import { Controller } from "@hotwired/stimulus"

/**
 * Sortable Stimulus Controller
 * Enables drag-and-drop reordering with auto-save
 * 
 * Usage:
 * <div data-controller="sortable"
 *      data-sortable-url-value="/path/to/update"
 *      data-sortable-handle-value=".drag-handle">
 *   <div data-sortable-id="1">Item 1</div>
 *   <div data-sortable-id="2">Item 2</div>
 * </div>
 */

// Module-level shared promise — prevents race conditions when multiple
// sortable controllers connect simultaneously and all try to load the CDN script.
let _sortableLoadPromise = null

function ensureSortableLoaded() {
  if (window.Sortable) return Promise.resolve()

  if (!_sortableLoadPromise) {
    _sortableLoadPromise = new Promise((resolve, reject) => {
      // Check if a script tag for SortableJS already exists in DOM
      const existing = document.querySelector('script[src*="sortablejs"]')
      if (existing) {
        // Script tag exists but library not yet on window — poll for it
        const check = setInterval(() => {
          if (window.Sortable) { clearInterval(check); resolve() }
        }, 50)
        setTimeout(() => { clearInterval(check); resolve() }, 10000)
        return
      }

      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js'
      script.onload = () => resolve()
      script.onerror = () => {
        // Reset promise so a future connect() can retry
        _sortableLoadPromise = null
        reject(new Error('SortableJS CDN load failed'))
      }
      document.head.appendChild(script)
    })
  }

  return _sortableLoadPromise
}

export default class extends Controller {
  static values = {
    url: String,
    handle: { type: String, default: ".section-handle" },
    animation: { type: Number, default: 150 }
  }
  
  connect() {
    this._destroyed = false
    this.initSortable()
  }
  
  async initSortable() {
    try {
      await ensureSortableLoaded()
    } catch (e) {
      console.error('[Sortable] Failed to load SortableJS library:', e)
      return
    }

    // Guard: element may have disconnected while we were loading the CDN script
    if (this._destroyed || !this.element || !this.element.isConnected) return

    // Guard: don't double-init if disconnect/reconnect happened
    if (this.sortable) return

    const isTbody = this.element.tagName === 'TBODY'

    if (!this.urlValue) {
      console.warn('[Sortable] Missing urlValue on element:', this.element)
    }

    const options = {
      animation: this.animationValue,
      handle: this.handleValue,
      ghostClass: 'sortable-ghost',
      dragClass: 'sortable-drag',
      forceFallback: true,          // Use custom drag impl — more reliable in overflow containers & Turbo Frames
      fallbackClass: 'sortable-fallback',
      fallbackOnBody: true,         // Append ghost to <body> so it isn't clipped by overflow:auto
      onEnd: this.onEnd.bind(this)
    }
    if (isTbody) options.draggable = 'tr'

    this.sortable = new window.Sortable(this.element, options)
    
    console.log('[Sortable] Connected', this.handleValue, this.urlValue)
  }

  disconnect() {
    this._destroyed = true
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  }
  
  async onEnd(event) {
    if (!this.urlValue) {
      console.warn('Sortable onEnd fired but urlValue is missing; skipping save', this.element)
      return
    }

    console.log('Sortable onEnd event', {
      oldIndex: event?.oldIndex,
      newIndex: event?.newIndex,
      from: event?.from,
      to: event?.to,
      item: event?.item,
    })

    // Get all items in new order
    const items = Array.from(this.element.children)
    const order = items.map((item, index) => ({
      id: item.dataset.sortableId,
      sequence: index + 1
    }))

    if (order.some((x) => !x.id)) {
      console.warn('Sortable missing data-sortable-id on one or more children; skipping save', order)
      return
    }
    
    console.log('New order:', order)
    
    // Auto-save the new order
    await this.saveOrder(order)
  }
  
  async saveOrder(order) {
    try {
      console.log('Sortable PATCH (reorder) begin', {
        url: this.urlValue,
        csrfPresent: Boolean(this.csrfToken()),
        order,
      })
      
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken(),
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify({ order: order })
      })

      const contentType = response.headers.get('content-type')
      const rawText = await response.text()
      let data = null
      try {
        data = rawText ? JSON.parse(rawText) : null
      } catch (e) {
        console.warn('Sortable reorder response was not valid JSON', {
          contentType,
          status: response.status,
          rawText,
        })
      }

      console.log('Sortable PATCH (reorder) response', {
        status: response.status,
        ok: response.ok,
        contentType,
        data,
        rawText,
      })
      
      if (response.ok) {
        this.showSuccess()
      } else {
        console.error('Sortable reorder save failed', {
          status: response.status,
          data,
          rawText,
        })
        this.showError()
      }
    } catch (error) {
      console.error('Sortable save error:', error)
      this.showError()
    }
  }
  
  showSuccess() {
    this.showIndicator('✓ Order saved', 'success')
  }
  
  showError() {
    this.showIndicator('⚠️ Save failed', 'error')
  }
  
  showIndicator(text, state) {
    let indicator = document.getElementById('auto-save-indicator')
    
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'auto-save-indicator'
      indicator.className = 'form-autosave-2025'
      document.body.appendChild(indicator)
    }
    
    indicator.textContent = text
    indicator.className = `form-autosave-2025 ${state}`
    
    // Hide after 2 seconds
    setTimeout(() => {
      indicator.className = 'form-autosave-2025'
    }, 2000)
  }
  
  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}
