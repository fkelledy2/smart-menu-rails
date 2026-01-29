import { Controller } from "@hotwired/stimulus"

/**
 * Auto-save Stimulus Controller
 * Automatically saves form changes after user stops typing (debounced)
 * 
 * Usage:
 * <form data-controller="auto-save"
 *       data-auto-save-url-value="/path/to/save"
 *       data-auto-save-method-value="patch">
 * </form>
 */
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "patch" },
    debounce: { type: Number, default: 1000 }
  }
  
  static targets = ["status"]
  
  connect() {
    this.timeout = null
    this.saving = false
    
    // Listen to all form inputs
    this.element.querySelectorAll('input, textarea, select').forEach(el => {
      el.addEventListener('input', this.handleInput.bind(this))
      el.addEventListener('change', this.handleChange.bind(this))
    })
    
    console.log('Auto-save connected', this.urlValue)
  }
  
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
  
  handleInput(event) {
    // Debounce text inputs
    if (event.target.type === 'text' || 
        event.target.type === 'textarea' ||
        event.target.type === 'email' ||
        event.target.type === 'url') {
      this.debounceSave()
    }
  }
  
  handleChange(event) {
    // Save immediately on select, checkbox, radio changes
    if (event.target.tagName === 'SELECT' ||
        event.target.type === 'checkbox' ||
        event.target.type === 'radio') {
      this.save()
    } else if (event.target.type === 'hidden') {
      // For hidden inputs (like our time inputs), debounce to batch multiple changes
      this.debounceSave()
    } else {
      // For other inputs, debounce
      this.debounceSave()
    }
  }
  
  debounceSave() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    this.timeout = setTimeout(() => {
      this.save()
    }, this.debounceValue)
  }
  
  async save() {
    if (this.saving) return
    
    console.log('[AutoSave] Saving changes...')
    this.saving = true
    this.showSaving()
    
    try {
      const formData = new FormData(this.element)
      
      const response = await fetch(this.urlValue, {
        method: this.methodValue.toUpperCase(),
        body: formData,
        headers: {
          'X-CSRF-Token': this.csrfToken(),
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        console.log('[AutoSave] ✓ Saved successfully')
        this.showSaved()
        this.updateOnboardingGuidance(data)
        this.dispatch('saved', { detail: data })
      } else {
        const errorData = await response.json()
        console.error('[AutoSave] ✗ Save failed:', errorData.error || errorData.errors || 'Unknown error')
        this.showError(errorData.error || errorData.errors || 'Save failed')
        this.dispatch('error', { detail: errorData })
      }
    } catch (error) {
      console.error('[AutoSave] ✗ Network error:', error.message)
      this.showError('Network error')
      this.dispatch('error', { detail: { message: error.message } })
    } finally {
      this.saving = false
    }
  }
  
  showSaving() {
    this.updateStatus('Saving...', 'saving')
    this.showIndicator('saving')
  }
  
  showSaved() {
    this.updateStatus('✓ Saved', 'saved')
    this.showIndicator('saved')
    
    // Hide after 2 seconds
    setTimeout(() => {
      this.hideIndicator()
    }, 2000)
  }
  
  showError(message) {
    const errorText = typeof message === 'string' ? message : 'Save failed'
    this.updateStatus(`⚠️ ${errorText}`, 'error')
    this.showIndicator('error')
    
    // Hide after 5 seconds
    setTimeout(() => {
      this.hideIndicator()
    }, 5000)
  }
  
  updateStatus(text, className) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = text
      this.statusTarget.className = `form-autosave-2025 ${className}`
    }
  }
  
  showIndicator(state) {
    // Create or update floating indicator
    let indicator = document.getElementById('auto-save-indicator')
    
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'auto-save-indicator'
      indicator.className = 'form-autosave-2025'
      document.body.appendChild(indicator)
    }
    
    if (state === 'saving') {
      indicator.textContent = 'Saving...'
      indicator.className = 'form-autosave-2025 saving'
    } else if (state === 'saved') {
      indicator.textContent = 'Saved'
      indicator.className = 'form-autosave-2025 saved'
    } else if (state === 'error') {
      indicator.textContent = 'Save failed'
      indicator.className = 'form-autosave-2025 error'
    }
  }
  
  hideIndicator() {
    const indicator = document.getElementById('auto-save-indicator')
    if (indicator) {
      indicator.className = 'form-autosave-2025'
    }
  }
  
  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  updateOnboardingGuidance(data) {
    if (!data || typeof data !== 'object') return

    const banner = document.querySelector('[data-testid="onboarding-guidance"]')
    if (!banner) return

    if (!data.onboarding_next) {
      banner.remove()
      return
    }

    if (!data.onboarding_required_text) return

    const content = banner.querySelector('div')
    if (!content) return

    content.innerHTML = `<strong>Required step</strong>: ${data.onboarding_required_text}`
  }
}
