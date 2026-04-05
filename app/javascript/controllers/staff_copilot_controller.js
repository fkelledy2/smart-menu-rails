import { Controller } from '@hotwired/stimulus'

// StaffCopilotController — manages the collapsible copilot panel.
//
// Responsibilities:
//   - expand / collapse the panel
//   - submit natural-language queries via Turbo Streams (fetch)
//   - maintain in-browser session history (max 5 turns)
//   - handle loading indicator
//   - Cmd/Ctrl+Enter shortcut to submit
//   - mobile touch support (works on any pointer input)

export default class extends Controller {
  static targets = ['panelBody', 'queryInput', 'submitButton', 'loadingIndicator', 'responseArea', 'form']
  static values  = { queryUrl: String, confirmUrl: String, pageContext: String }

  connect () {
    this._history = []      // [{ query, response }] — max 5 turns, ephemeral
    this._expanded = false
    this._loading  = false
    this._csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''
  }

  // ---------------------------------------------------------------------------
  // Panel toggle
  // ---------------------------------------------------------------------------

  toggle () {
    this._expanded = !this._expanded
    const body   = this.panelBodyTarget
    const toggle = this.element.querySelector('.staff-copilot-panel__toggle')

    if (this._expanded) {
      body.setAttribute('aria-hidden', 'false')
      this.element.classList.add('staff-copilot-panel--open')
      toggle?.setAttribute('aria-expanded', 'true')
      this.queryInputTarget.focus()
    } else {
      body.setAttribute('aria-hidden', 'true')
      this.element.classList.remove('staff-copilot-panel--open')
      toggle?.setAttribute('aria-expanded', 'false')
    }
  }

  // ---------------------------------------------------------------------------
  // Form submission
  // ---------------------------------------------------------------------------

  handleKeydown (event) {
    // Cmd/Ctrl+Enter submits; plain Enter adds newline (textarea default)
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault()
      this.submit(event)
    }
  }

  async submit (event) {
    event.preventDefault()
    if (this._loading) return

    const query = this.queryInputTarget.value.trim()
    if (!query) return

    this._setLoading(true)
    this.queryInputTarget.value = ''

    try {
      const body = new URLSearchParams({
        query_text:           query,
        page_context:         this.pageContextValue,
        conversation_history: JSON.stringify(this._history),
      })

      const response = await fetch(this.queryUrlValue, {
        method:  'POST',
        headers: {
          'X-CSRF-Token':  this._csrfToken,
          'Content-Type':  'application/x-www-form-urlencoded',
          'Accept':        'text/vnd.turbo-stream.html',
        },
        body: body.toString(),
      })

      if (!response.ok && response.status === 429) {
        this._renderRateLimitMessage()
        return
      }

      const html = await response.text()
      await import('@hotwired/turbo').then(({ renderStreamMessage }) => renderStreamMessage(html))

      // Track the turn in session history
      this._pushHistory(query)
    } catch (err) {
      console.error('[StaffCopilot] Query error:', err)
      this._renderError('Network error. Please try again.')
    } finally {
      this._setLoading(false)
    }
  }

  // ---------------------------------------------------------------------------
  // Session history
  // ---------------------------------------------------------------------------

  _pushHistory (query) {
    const responseText = this.responseAreaTarget?.innerText?.trim() || ''
    this._history.push({ query, response: responseText })
    if (this._history.length > 5) this._history.shift()
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  _setLoading (loading) {
    this._loading = loading

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = loading
    }

    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.toggle('d-none', !loading)
    }

    if (this.hasQueryInputTarget) {
      this.queryInputTarget.disabled = loading
    }
  }

  // ---------------------------------------------------------------------------
  // Error rendering (fallback when Turbo stream fails)
  // ---------------------------------------------------------------------------

  _renderRateLimitMessage () {
    if (this.hasResponseAreaTarget) {
      this.responseAreaTarget.innerHTML = `
        <div class="copilot-narrative copilot-narrative--error" role="alert">
          <i class="bi bi-clock-history text-warning me-2" aria-hidden="true"></i>
          <span>You've reached the hourly limit for copilot queries. Please try again later.</span>
        </div>`
    }
  }

  _renderError (message) {
    if (this.hasResponseAreaTarget) {
      this.responseAreaTarget.innerHTML = `
        <div class="copilot-narrative copilot-narrative--error" role="alert">
          <i class="bi bi-exclamation-triangle text-warning me-2" aria-hidden="true"></i>
          <span>${this._escapeHtml(message)}</span>
        </div>`
    }
  }

  _escapeHtml (text) {
    const div = document.createElement('div')
    div.appendChild(document.createTextNode(text))
    return div.innerHTML
  }
}
