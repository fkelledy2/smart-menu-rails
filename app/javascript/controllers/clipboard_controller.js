import { Controller } from '@hotwired/stimulus'

// Copies a text value to the clipboard. Shows brief success feedback.
// Usage:
//   <button data-controller="clipboard"
//           data-clipboard-text-value="text to copy"
//           data-action="clipboard#copy">Copy</button>
export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()

    const text = this.textValue
    if (!text) return

    try {
      await navigator.clipboard.writeText(text)
      this.#showSuccess()
    } catch {
      // Fallback for older browsers
      const el = document.createElement('textarea')
      el.value = text
      el.style.position = 'fixed'
      el.style.opacity = '0'
      document.body.appendChild(el)
      el.select()
      document.execCommand('copy')
      document.body.removeChild(el)
      this.#showSuccess()
    }
  }

  #showSuccess() {
    const original = this.element.innerHTML
    this.element.innerHTML = '<i class="bi bi-check2 me-1" aria-hidden="true"></i>Copied!'
    this.element.classList.add('btn-success')
    this.element.classList.remove('btn-outline-secondary')
    setTimeout(() => {
      this.element.innerHTML = original
      this.element.classList.remove('btn-success')
      this.element.classList.add('btn-outline-secondary')
    }, 2000)
  }
}
