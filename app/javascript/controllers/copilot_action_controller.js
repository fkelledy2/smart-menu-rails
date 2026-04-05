import { Controller } from '@hotwired/stimulus'

// CopilotActionController — handles confirm/cancel on copilot action cards.
//
// Wires up the Confirm and Cancel buttons rendered inside a copilot action card.
// On confirm, collects confirm_params from hidden inputs and POSTs to the confirm
// endpoint. On cancel, clears the copilot response area.

export default class extends Controller {
  static values = {
    toolName:    String,
    menuitemId:  Number,
    hide:        Boolean,
  }

  connect () {
    this._csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''
    this._loading   = false
  }

  // Called from the Confirm button on an action_card.
  async confirm (event) {
    event.preventDefault()
    if (this._loading) return

    const confirmUrl = this._resolveConfirmUrl(event)
    if (!confirmUrl) {
      console.error('[CopilotAction] No confirm URL found')
      return
    }

    this._loading = true
    const btn = event.currentTarget
    btn.disabled = true

    try {
      const body = this._buildConfirmBody()

      const response = await fetch(confirmUrl, {
        method:  'POST',
        headers: {
          'X-CSRF-Token': this._csrfToken,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept':       'text/vnd.turbo-stream.html',
        },
        body: body.toString(),
      })

      const html = await response.text()
      await import('@hotwired/turbo').then(({ renderStreamMessage }) => renderStreamMessage(html))
    } catch (err) {
      console.error('[CopilotAction] Confirm error:', err)
    } finally {
      this._loading = false
    }
  }

  // Called from the Confirm button on a disambiguation option.
  confirmDisambiguation (event) {
    event.preventDefault()
    this.confirm(event)
  }

  // Cancel — clear the response area back to idle state.
  cancel (event) {
    event.preventDefault()
    const responseArea = document.getElementById('copilot-response')
    if (responseArea) {
      responseArea.innerHTML = `
        <p class="text-muted small mb-0">
          <i class="bi bi-lightbulb me-1" aria-hidden="true"></i>
          Action cancelled. What else can I help with?
        </p>`
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  _resolveConfirmUrl (event) {
    // Try data-confirm-url on the button, then on nearest panel
    const btn   = event.currentTarget
    const panel = document.getElementById('staff-copilot-panel')
    return btn.dataset.confirmUrl || panel?.dataset?.staffCopilotConfirmUrlValue || null
  }

  _buildConfirmBody () {
    const params = new URLSearchParams()
    params.set('tool_name', this.toolNameValue)

    // Collect hidden param inputs within this action card element
    this.element.querySelectorAll('[data-copilot-action-target="param"]').forEach((input) => {
      const key   = input.dataset.paramKey
      const value = input.value
      if (key && value !== '') params.append(key, value)
    })

    // Editable body field (staff_message tool)
    const editableBody = this.element.querySelector('[data-copilot-action-target="editableBody"]')
    if (editableBody) params.set('body', editableBody.value)

    // Subject field
    const subjectInput = this.element.querySelector('[data-copilot-action-target="subject"]')
    if (subjectInput) params.set('subject', subjectInput.value)

    // Disambiguation shortcut values from controller values
    if (this.hasMenuitemIdValue && this.menuitemIdValue) {
      params.set('menuitem_id', this.menuitemIdValue)
    }
    if (this.hasHideValue) {
      params.set('hide', this.hideValue ? 'true' : 'false')
    }

    return params
  }
}
