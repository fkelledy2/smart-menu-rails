import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    this.timer = setInterval(() => {
      if (document.visibilityState === 'visible') location.reload()
    }, 30000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
