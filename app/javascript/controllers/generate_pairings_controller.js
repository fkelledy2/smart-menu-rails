import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "spinner", "results", "count", "error", "pairingsBody"]
  static values  = { url: String }

  generate(event) {
    event.preventDefault()

    // Show modal with spinner
    this.showModal()
    this.spinnerTarget.classList.remove("d-none")
    this.resultsTarget.classList.add("d-none")
    this.errorTarget.classList.add("d-none")
    this.pairingsBodyTarget.innerHTML = ""

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken,
      },
    })
      .then(response => {
        if (!response.ok) throw new Error(`Server returned ${response.status}`)
        return response.json()
      })
      .then(data => {
        this.spinnerTarget.classList.add("d-none")

        if (data.error) {
          this.errorTarget.textContent = data.error
          this.errorTarget.classList.remove("d-none")
          return
        }

        this.countTarget.textContent = `${data.pairings_count} pairing${data.pairings_count === 1 ? '' : 's'} generated`
        this.renderPairings(data.pairings)
        this.resultsTarget.classList.remove("d-none")
      })
      .catch(err => {
        this.spinnerTarget.classList.add("d-none")
        this.errorTarget.textContent = `Failed to generate pairings: ${err.message}`
        this.errorTarget.classList.remove("d-none")
      })
  }

  renderPairings(pairings) {
    if (!pairings || pairings.length === 0) {
      this.pairingsBodyTarget.innerHTML = '<p class="text-muted text-center py-3">No pairings could be generated.</p>'
      return
    }

    // Group pairings by drink
    const grouped = {}
    pairings.forEach(p => {
      const key = p.drink_name
      if (!grouped[key]) grouped[key] = { drink: p, foods: [] }
      grouped[key].foods.push(p)
    })

    let html = '<div class="pairings-list">'

    Object.values(grouped).forEach(group => {
      const drink = group.drink
      const typeLabel = drink.drink_type || ''
      const typeBadge = typeLabel
        ? `<span class="badge bg-secondary-subtle text-secondary ms-2">${typeLabel}</span>`
        : ''

      html += `<div class="pairing-group mb-3">`
      html += `<div class="pairing-drink-header d-flex align-items-center mb-2">`
      html += `  <i class="bi bi-cup-straw text-primary me-2"></i>`
      html += `  <strong>${this.escapeHtml(drink.drink_name)}</strong>${typeBadge}`
      html += `</div>`
      html += `<div class="pairing-food-list ms-4">`

      group.foods.forEach(p => {
        const score = Math.round((p.score || 0) * 100)
        const typeBadgeClass = p.pairing_type === 'surprise' ? 'bg-warning-subtle text-warning' : 'bg-success-subtle text-success'
        const typeIcon = p.pairing_type === 'surprise' ? 'bi-lightning' : 'bi-heart'
        const scoreColor = score >= 60 ? 'text-success' : score >= 30 ? 'text-warning' : 'text-muted'

        html += `<div class="pairing-food-item d-flex align-items-start py-2 border-bottom">`
        html += `  <div class="flex-grow-1">`
        html += `    <div class="d-flex align-items-center">`
        html += `      <i class="bi ${typeIcon} me-2 ${typeBadgeClass.split(' ')[1]}"></i>`
        html += `      <span>${this.escapeHtml(p.food_name)}</span>`
        html += `      <span class="badge ${typeBadgeClass} ms-2" style="font-size:0.7rem">${p.pairing_type || 'complement'}</span>`
        html += `    </div>`
        if (p.rationale) {
          html += `<small class="text-muted d-block mt-1">${this.escapeHtml(p.rationale)}</small>`
        }
        html += `  </div>`
        html += `  <div class="ms-3 text-end flex-shrink-0">`
        html += `    <span class="fw-bold ${scoreColor}">${score}%</span>`
        html += `  </div>`
        html += `</div>`
      })

      html += `</div></div>`
    })

    html += '</div>'
    this.pairingsBodyTarget.innerHTML = html
  }

  showModal() {
    const modal = new bootstrap.Modal(this.modalTarget)
    modal.show()
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text || ''
    return div.innerHTML
  }
}
