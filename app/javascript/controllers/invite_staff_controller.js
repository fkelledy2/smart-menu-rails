import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show(event) {
    event.preventDefault()
    const wrapper = document.getElementById('staff_invite_form_wrapper')
    if (wrapper) {
      wrapper.style.display = wrapper.style.display === 'none' ? 'block' : 'none'
      if (wrapper.style.display === 'block') {
        wrapper.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
  }
}
