import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    statusUrl: String,
    initialStatus: String,
  }

  connect() {
    this.pollHandle = null

    const status = (this.initialStatusValue || '').toLowerCase()
    if (['queued', 'scraping', 'processing'].includes(status)) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    if (!this.statusUrlValue) return
    if (this.pollHandle) return

    this.pollHandle = window.setInterval(() => {
      this.checkOnce()
    }, 2500)

    this.checkOnce()
  }

  stopPolling() {
    if (!this.pollHandle) return
    window.clearInterval(this.pollHandle)
    this.pollHandle = null
  }

  async checkOnce() {
    try {
      const resp = await fetch(this.statusUrlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin',
      })

      if (!resp.ok) return

      const data = await resp.json()
      const status = (data.status || '').toLowerCase()

      if (status === 'completed' || status === 'failed') {
        this.stopPolling()
        window.location.reload()
      }
    } catch (_e) {
      // ignore
    }
  }
}
