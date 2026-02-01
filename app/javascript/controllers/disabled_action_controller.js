import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    message: String,
  }

  explain(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const title = this.hasTitleValue && this.titleValue ? this.titleValue : "Action unavailable"
    const message = this.hasMessageValue && this.messageValue ? this.messageValue : "This action is unavailable."

    const modalId = "disabledActionModal"
    let modalEl = document.getElementById(modalId)

    if (!modalEl) {
      modalEl = document.createElement("div")
      modalEl.id = modalId
      modalEl.className = "modal fade"
      modalEl.tabIndex = -1
      modalEl.setAttribute("aria-hidden", "true")
      modalEl.innerHTML = `
        <div class="modal-dialog modal-dialog-centered">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="${modalId}Label"></h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" data-disabled-action-modal-body></div>
            <div class="modal-footer">
              <button type="button" class="btn btn-primary" data-bs-dismiss="modal">OK</button>
            </div>
          </div>
        </div>
      `
      document.body.appendChild(modalEl)
    }

    const titleEl = modalEl.querySelector(".modal-title")
    const bodyEl = modalEl.querySelector("[data-disabled-action-modal-body]")
    if (titleEl) titleEl.textContent = title
    if (bodyEl) bodyEl.textContent = message

    if (window.bootstrap && window.bootstrap.Modal) {
      const instance = window.bootstrap.Modal.getOrCreateInstance(modalEl)
      instance.show()
    }
  }
}
