import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "loading", "error", "errorMessage",
    "methodSelector", "planView",
    "participantsList", "equalPreview", "equalAmount",
    "customInputs", "customAmountsList", "customTotal",
    "percentageInputs", "percentageAmountsList", "percentageTotal",
    "itemInputs", "itemAssignmentsList",
    "createButton", "payShareButton",
    "planStatus", "planDetails", "myShareAmount"
  ]

  static values = {
    orderId: String,
    restaurantId: String,
    participantId: String,
    currencySymbol: String,
    currencyCode: String
  }

  connect() {
    this.currentMethod = 'equal'
    this.participants = []
    this.orderItems = []
    this.orderTotal = 0
    this.existingPlan = null
    
    // Listen for realtime state updates
    this._onStateUpdate = this.handleStateUpdate.bind(this)
    document.addEventListener('state:update', this._onStateUpdate)
    
    this.loadParticipantsAndPlan()
  }

  disconnect() {
    if (this._onStateUpdate) {
      document.removeEventListener('state:update', this._onStateUpdate)
    }
  }

  handleStateUpdate(event) {
    const state = event.detail || {}
    const splitPlan = state.splitPlan
    
    if (!splitPlan) {
      // Split plan was removed/cleared
      if (this.existingPlan) {
        console.log('[SplitBill] Plan removed, refreshing UI')
        this.existingPlan = null
        this.renderParticipants()
      }
      return
    }
    
    // Check if plan changed
    const planChanged = !this.existingPlan || 
                       this.existingPlan.id !== splitPlan.id ||
                       this.existingPlan.planStatus !== splitPlan.planStatus ||
                       this.existingPlan.frozen !== splitPlan.frozen
    
    if (planChanged) {
      console.log('[SplitBill] Plan updated via WebSocket, refreshing UI')
      this.existingPlan = splitPlan
      
      if (splitPlan.frozen) {
        this.showExistingPlan()
      } else {
        this.renderParticipants()
        this.updatePreview()
      }
    }
  }

  async loadParticipantsAndPlan() {
    this.showLoading()
    
    try {
      // Load order to get participants
      const orderResponse = await fetch(`/restaurants/${this.restaurantIdValue}/ordrs/${this.orderIdValue}.json`)
      if (!orderResponse.ok) {
        const errorText = await orderResponse.text()
        console.error('[SplitBill] Order fetch failed:', orderResponse.status, errorText)
        throw new Error(`Failed to load order: ${orderResponse.status}`)
      }
      
      const responseText = await orderResponse.text()
      console.log('[SplitBill] Order response:', responseText.substring(0, 200))
      
      let orderData
      try {
        orderData = JSON.parse(responseText)
      } catch (e) {
        console.error('[SplitBill] JSON parse error:', e, 'Response:', responseText)
        throw new Error('Invalid response from server')
      }
      
      this.participants = (orderData.ordrparticipants || []).filter(p => p.role === 'customer' && p.sessionid)
      this.orderItems = orderData.ordritems || []
      this.orderTotal = Math.round((orderData.gross - orderData.tip) * 100)
      
      // Load existing split plan if any
      const planResponse = await fetch(`/restaurants/${this.restaurantIdValue}/ordrs/${this.orderIdValue}/split_plan`)
      if (planResponse.ok) {
        const planData = await planResponse.json()
        if (planData.ok && planData.split_plan) {
          this.existingPlan = planData.split_plan
        }
      }
      
      this.hideLoading()
      
      if (this.existingPlan) {
        this.showExistingPlan()
      } else {
        this.renderParticipants()
        this.updatePreview()
      }
    } catch (error) {
      this.showError(error.message)
    }
  }

  renderParticipants() {
    const html = this.participants.map((p, index) => {
      const isMe = p.id.toString() === this.participantIdValue
      const label = isMe ? `Participant ${index + 1} (You)` : `Participant ${index + 1}`
      
      return `
        <div class="form-check">
          <input class="form-check-input" type="checkbox" value="${p.id}" 
                 id="participant${p.id}" checked
                 data-action="change->split-bill#participantChanged">
          <label class="form-check-label" for="participant${p.id}">
            ${label}
          </label>
        </div>
      `
    }).join('')
    
    this.participantsListTarget.innerHTML = html
  }

  methodChanged(event) {
    this.currentMethod = event.target.value
    this.updatePreview()
  }

  participantChanged() {
    this.updatePreview()
  }

  updatePreview() {
    const selectedParticipants = this.getSelectedParticipants()
    
    // Hide all previews first
    this.equalPreviewTarget.style.display = 'none'
    this.customInputsTarget.style.display = 'none'
    this.percentageInputsTarget.style.display = 'none'
    this.itemInputsTarget.style.display = 'none'
    
    if (selectedParticipants.length === 0) {
      this.createButtonTarget.disabled = true
      return
    }
    
    this.createButtonTarget.disabled = false
    
    switch (this.currentMethod) {
      case 'equal':
        this.showEqualPreview(selectedParticipants)
        break
      case 'custom':
        this.showCustomInputs(selectedParticipants)
        break
      case 'percentage':
        this.showPercentageInputs(selectedParticipants)
        break
      case 'item_based':
        this.showItemInputs(selectedParticipants)
        break
    }
  }

  showEqualPreview(participants) {
    this.equalPreviewTarget.style.display = 'block'
    const amountPerPerson = this.orderTotal / participants.length
    this.equalAmountTarget.textContent = this.formatCurrency(amountPerPerson)
  }

  showCustomInputs(participants) {
    this.customInputsTarget.style.display = 'block'
    
    const html = participants.map(p => {
      const isMe = p.id.toString() === this.participantIdValue
      const label = isMe ? '(You)' : ''
      
      return `
        <div class="input-group mb-2">
          <span class="input-group-text">Participant ${label}</span>
          <input type="number" class="form-control" 
                 data-participant-id="${p.id}"
                 data-action="input->split-bill#customAmountChanged"
                 placeholder="0.00" step="0.01" min="0">
          <span class="input-group-text">${this.currencySymbolValue}</span>
        </div>
      `
    }).join('')
    
    this.customAmountsListTarget.innerHTML = html
    this.updateCustomTotal()
  }

  customAmountChanged() {
    this.updateCustomTotal()
  }

  updateCustomTotal() {
    const inputs = this.customAmountsListTarget.querySelectorAll('input[type="number"]')
    let total = 0
    
    inputs.forEach(input => {
      const value = parseFloat(input.value) || 0
      total += Math.round(value * 100)
    })
    
    this.customTotalTarget.textContent = this.formatCurrency(total)
    
    // Highlight if total doesn't match
    if (total === this.orderTotal) {
      this.customTotalTarget.classList.remove('text-danger')
      this.customTotalTarget.classList.add('text-success')
    } else {
      this.customTotalTarget.classList.remove('text-success')
      this.customTotalTarget.classList.add('text-danger')
    }
  }

  showPercentageInputs(participants) {
    this.percentageInputsTarget.style.display = 'block'
    
    const html = participants.map(p => {
      const isMe = p.id.toString() === this.participantIdValue
      const label = isMe ? '(You)' : ''
      
      return `
        <div class="input-group mb-2">
          <span class="input-group-text">Participant ${label}</span>
          <input type="number" class="form-control" 
                 data-participant-id="${p.id}"
                 data-action="input->split-bill#percentageChanged"
                 placeholder="0" step="1" min="0" max="100">
          <span class="input-group-text">%</span>
        </div>
      `
    }).join('')
    
    this.percentageAmountsListTarget.innerHTML = html
    this.updatePercentageTotal()
  }

  percentageChanged() {
    this.updatePercentageTotal()
  }

  updatePercentageTotal() {
    const inputs = this.percentageAmountsListTarget.querySelectorAll('input[type="number"]')
    let total = 0
    
    inputs.forEach(input => {
      const value = parseFloat(input.value) || 0
      total += value
    })
    
    this.percentageTotalTarget.textContent = `${total.toFixed(1)}%`
    
    // Highlight if total doesn't equal 100%
    if (Math.abs(total - 100) < 0.01) {
      this.percentageTotalTarget.classList.remove('text-danger')
      this.percentageTotalTarget.classList.add('text-success')
    } else {
      this.percentageTotalTarget.classList.remove('text-success')
      this.percentageTotalTarget.classList.add('text-danger')
    }
  }

  showItemInputs(participants) {
    this.itemInputsTarget.style.display = 'block'
    
    const payableItems = this.orderItems.filter(item => item.status !== 'removed')
    
    const html = payableItems.map(item => {
      return `
        <div class="card mb-2">
          <div class="card-body p-2">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <span class="fw-bold">${item.name}</span>
              <span>${this.formatCurrency(item.price * 100)}</span>
            </div>
            <select class="form-select form-select-sm" 
                    data-item-id="${item.id}"
                    data-action="change->split-bill#itemAssignmentChanged">
              <option value="">Unassigned</option>
              ${participants.map(p => {
                const isMe = p.id.toString() === this.participantIdValue
                const label = isMe ? '(You)' : ''
                return `<option value="${p.id}">Participant ${label}</option>`
              }).join('')}
            </select>
          </div>
        </div>
      `
    }).join('')
    
    this.itemAssignmentsListTarget.innerHTML = html
  }

  itemAssignmentChanged() {
    // Could add preview of per-participant totals here
  }

  validateSplitPlan() {
    const errors = []
    const selectedParticipants = this.getSelectedParticipants()
    
    if (selectedParticipants.length === 0) {
      errors.push('Select at least one participant')
      return errors
    }
    
    if (this.currentMethod === 'custom') {
      const inputs = this.customAmountsListTarget.querySelectorAll('input[type="number"]')
      let total = 0
      let hasEmptyInputs = false
      
      inputs.forEach(input => {
        const value = parseFloat(input.value)
        if (!value || value <= 0) {
          hasEmptyInputs = true
        }
        total += Math.round((value || 0) * 100)
      })
      
      if (hasEmptyInputs) {
        errors.push('Enter an amount for each participant')
      }
      
      if (total !== this.orderTotal) {
        const diff = Math.abs(total - this.orderTotal) / 100
        errors.push(`Total amounts must equal order total (off by ${this.formatCurrency(Math.abs(total - this.orderTotal))})`)
      }
    } else if (this.currentMethod === 'percentage') {
      const inputs = this.percentageAmountsListTarget.querySelectorAll('input[type="number"]')
      let total = 0
      let hasEmptyInputs = false
      
      inputs.forEach(input => {
        const value = parseFloat(input.value)
        if (!value || value <= 0) {
          hasEmptyInputs = true
        }
        total += value || 0
      })
      
      if (hasEmptyInputs) {
        errors.push('Enter a percentage for each participant')
      }
      
      if (Math.abs(total - 100) > 0.01) {
        errors.push(`Total percentages must equal 100% (currently ${total.toFixed(1)}%)`)
      }
    } else if (this.currentMethod === 'item_based') {
      const selects = this.itemAssignmentsListTarget.querySelectorAll('select')
      let hasUnassigned = false
      
      selects.forEach(select => {
        if (!select.value) {
          hasUnassigned = true
        }
      })
      
      if (hasUnassigned) {
        errors.push('All items must be assigned to a participant')
      }
    }
    
    return errors
  }

  async createPlan() {
    this.hideError()
    
    // Validate before sending
    const validationErrors = this.validateSplitPlan()
    if (validationErrors.length > 0) {
      this.showError('Cannot create split plan:', validationErrors)
      return
    }
    
    this.showLoading()
    
    try {
      const selectedParticipants = this.getSelectedParticipants()
      const params = {
        split_method: this.currentMethod,
        participant_ids: selectedParticipants.map(p => p.id)
      }
      
      if (this.currentMethod === 'custom') {
        const customAmounts = {}
        const inputs = this.customAmountsListTarget.querySelectorAll('input[type="number"]')
        
        inputs.forEach(input => {
          const participantId = input.dataset.participantId
          const amountCents = Math.round((parseFloat(input.value) || 0) * 100)
          customAmounts[participantId] = amountCents
        })
        
        params.custom_amounts_cents = customAmounts
      } else if (this.currentMethod === 'percentage') {
        const percentages = {}
        const inputs = this.percentageAmountsListTarget.querySelectorAll('input[type="number"]')
        
        inputs.forEach(input => {
          const participantId = input.dataset.participantId
          const percentage = parseFloat(input.value) || 0
          percentages[participantId] = percentage
        })
        
        params.percentages = percentages
      } else if (this.currentMethod === 'item_based') {
        const itemAssignments = {}
        const selects = this.itemAssignmentsListTarget.querySelectorAll('select')
        
        selects.forEach(select => {
          const itemId = select.dataset.itemId
          const participantId = select.value
          
          if (participantId) {
            if (!itemAssignments[participantId]) {
              itemAssignments[participantId] = []
            }
            itemAssignments[participantId].push(parseInt(itemId))
          }
        })
        
        params.item_assignments = itemAssignments
      }
      
      const response = await fetch(`/restaurants/${this.restaurantIdValue}/ordrs/${this.orderIdValue}/split_plan`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify(params)
      })
      
      const data = await response.json()
      
      if (!response.ok || !data.ok) {
        throw new Error(data.error || 'Failed to create split plan')
      }
      
      this.existingPlan = data.split_plan
      this.hideLoading()
      this.showExistingPlan()
    } catch (error) {
      this.showError(error.message)
    }
  }

  showExistingPlan() {
    this.methodSelectorTarget.style.display = 'none'
    this.planViewTarget.style.display = 'block'
    
    const myShare = this.existingPlan.shares.find(s => 
      s.ordrparticipant_id.toString() === this.participantIdValue
    )
    
    if (myShare) {
      this.myShareAmountTarget.textContent = this.formatCurrency(myShare.amount_cents)
      
      const canPay = myShare.status === 'requires_payment' || myShare.status === 'failed'
      this.payShareButtonTarget.disabled = !canPay
    }
    
    this.planStatusTarget.textContent = this.existingPlan.plan_status
    this.planDetailsTarget.textContent = `${this.existingPlan.split_method} split among ${this.existingPlan.participant_count} participants`
  }

  async payMyShare() {
    const myShare = this.existingPlan.shares.find(s => 
      s.ordrparticipant_id.toString() === this.participantIdValue
    )
    
    if (!myShare) {
      this.showError('Your share not found')
      return
    }
    
    // Redirect to checkout with split payment ID
    const checkoutUrl = `/restaurants/${this.restaurantIdValue}/ordrs/${this.orderIdValue}/payments/checkout_session?ordr_split_payment_id=${myShare.id}`
    window.location.href = checkoutUrl
  }

  cancel() {
    this.element.style.display = 'none'
    document.getElementById('cartPaySection').style.display = 'none'
  }

  getSelectedParticipants() {
    const checkboxes = this.participantsListTarget.querySelectorAll('input[type="checkbox"]:checked')
    return Array.from(checkboxes).map(cb => {
      const id = cb.value
      return this.participants.find(p => p.id.toString() === id)
    }).filter(Boolean)
  }

  formatCurrency(cents) {
    const amount = cents / 100
    return `${this.currencySymbolValue}${amount.toFixed(2)}`
  }

  showLoading() {
    this.loadingTarget.style.display = 'block'
    this.errorTarget.style.display = 'none'
    if (this.hasMethodSelectorTarget) this.methodSelectorTarget.style.display = 'none'
    if (this.hasPlanViewTarget) this.planViewTarget.style.display = 'none'
  }

  hideLoading() {
    this.loadingTarget.style.display = 'none'
    this.methodSelectorTarget.style.display = 'block'
  }

  showError(message, details = null) {
    this.hideLoading()
    this.errorTarget.style.display = 'block'
    
    let errorHtml = `<strong>${message}</strong>`
    
    if (details) {
      if (typeof details === 'string') {
        errorHtml += `<br><small>${details}</small>`
      } else if (Array.isArray(details)) {
        errorHtml += '<ul class="mb-0 mt-2">'
        details.forEach(detail => {
          errorHtml += `<li><small>${detail}</small></li>`
        })
        errorHtml += '</ul>'
      }
    }
    
    this.errorMessageTarget.innerHTML = errorHtml
  }

  hideError() {
    this.errorTarget.style.display = 'none'
    this.errorMessageTarget.innerHTML = ''
  }
}
