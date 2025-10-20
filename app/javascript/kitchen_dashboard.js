// Kitchen Dashboard - Real-time order management for large screen displays
// Note: This file is loaded via javascript_include_tag, not as an ES6 module

class KitchenDashboard {
  constructor() {
    this.restaurantId = document.querySelector('.kitchen-dashboard')?.dataset.restaurantId
    if (!this.restaurantId) return
    
    this.initializeClock()
    this.initializeKitchenChannel()
    this.initializeNotificationSound()
    this.initializeOrderStatusButtons()
    this.initializeSortButtons()
  }
  
  initializeClock() {
    const updateClock = () => {
      const now = new Date()
      const timeString = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
      const dateString = now.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })
      
      const clockElement = document.getElementById('current-time')
      if (clockElement) {
        clockElement.textContent = `${dateString} - ${timeString}`
      }
    }
    
    updateClock()
    setInterval(updateClock, 1000)
  }
  
  initializeKitchenChannel() {
    // Access the global App.cable consumer
    if (!window.App || !window.App.cable) {
      console.error('Action Cable not available')
      return
    }
    
    this.kitchenChannel = window.App.cable.subscriptions.create(
      { channel: 'KitchenChannel', restaurant_id: this.restaurantId },
      {
        connected: () => {
          console.log('Kitchen dashboard connected')
          this.showConnectionStatus(true)
        },
        
        disconnected: () => {
          console.log('Kitchen dashboard disconnected')
          this.showConnectionStatus(false)
        },
        
        received: (data) => {
          console.log('Kitchen update received:', data)
          this.handleKitchenMessage(data)
        }
      }
    )
  }
  
  handleKitchenMessage(data) {
    switch(data.event) {
      case 'new_order':
        console.log('New order received:', data.order)
        this.addOrderToColumn(data.order, 'pending')
        this.updateMetric('pending', 1)
        this.playNotificationSound()
        this.showNotification('New Order', `Order #${data.order.id} received`)
        break
      case 'status_change':
        console.log('Order status changed:', data)
        this.moveOrderBetweenColumns(data.order_id, data.old_status, data.new_status)
        this.updateMetricsFromStatusChange(data.old_status, data.new_status)
        break
      case 'queue_update':
        console.log('Queue updated:', data)
        this.updateMetric('pending', data.queue_length)
        break
    }
  }
  
  initializeNotificationSound() {
    // Create a simple beep sound using Web Audio API
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
  }
  
  initializeOrderStatusButtons() {
    // Use event delegation for dynamically added order cards
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.order-status-btn')
      if (!button) return
      
      const orderId = button.dataset.orderId
      const newStatus = button.dataset.newStatus
      
      if (orderId && newStatus) {
        this.updateOrderStatus(orderId, newStatus)
      }
    })
  }
  
  updateOrderStatus(orderId, newStatus) {
    fetch(`/restaurants/${this.restaurantId}/ordrs/${orderId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        ordr: { status: newStatus }
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      console.log('Order updated:', data)
    })
    .catch(error => {
      console.error('Error updating order:', error)
      alert('Failed to update order status')
    })
  }
  
  initializeSortButtons() {
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.sort-btn')
      if (!button) return
      
      const column = button.dataset.column
      const direction = button.dataset.direction
      
      this.sortColumn(column, direction)
    })
  }
  
  sortColumn(columnName, direction) {
    const columnId = `${columnName}-orders`
    const column = document.getElementById(columnId)
    if (!column) return
    
    const cards = Array.from(column.querySelectorAll('.order-card'))
    
    cards.sort((a, b) => {
      const timeA = parseInt(a.dataset.createdAt)
      const timeB = parseInt(b.dataset.createdAt)
      
      if (direction === 'asc') {
        return timeA - timeB // Oldest first
      } else {
        return timeB - timeA // Newest first
      }
    })
    
    // Clear and re-append sorted cards
    column.innerHTML = ''
    cards.forEach(card => column.appendChild(card))
    
    // Visual feedback
    const allButtons = document.querySelectorAll(`.sort-btn[data-column="${columnName}"]`)
    allButtons.forEach(btn => btn.classList.remove('active'))
    event.target.closest('.sort-btn')?.classList.add('active')
  }
  
  playNotificationSound() {
    try {
      const oscillator = this.audioContext.createOscillator()
      const gainNode = this.audioContext.createGain()
      
      oscillator.connect(gainNode)
      gainNode.connect(this.audioContext.destination)
      
      oscillator.frequency.value = 800
      oscillator.type = 'sine'
      
      gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.5)
      
      oscillator.start(this.audioContext.currentTime)
      oscillator.stop(this.audioContext.currentTime + 0.5)
    } catch (error) {
      console.error('Error playing notification sound:', error)
    }
  }
  
  showNotification(title, message) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        body: message,
        icon: '/icons/smart-menu-192.png'
      })
    }
  }
  
  showConnectionStatus(connected) {
    // Could add a visual indicator for connection status
    console.log('Connection status:', connected ? 'Connected' : 'Disconnected')
  }
  
  addOrderToColumn(order, columnType) {
    // columnType is 'pending', 'preparing', or 'ready'
    const columnId = `${columnType}-orders`
    const column = document.getElementById(columnId)
    
    if (!column) {
      console.error(`Column not found: ${columnId}`)
      return
    }
    
    console.log(`Adding order ${order.id} to column ${columnId}`)
    
    // Create order card HTML
    const orderCard = this.createOrderCardElement(order)
    orderCard.classList.add('new-order')
    
    // Add to top of column
    column.insertBefore(orderCard, column.firstChild)
    
    // Remove new-order animation after 3 seconds
    setTimeout(() => {
      orderCard.classList.remove('new-order')
    }, 3000)
  }
  
  moveOrderBetweenColumns(orderId, oldStatus, newStatus) {
    const orderCard = document.querySelector(`[data-order-id="${orderId}"]`)
    
    // If card doesn't exist and new status is kitchen-relevant, fetch and create it
    if (!orderCard) {
      if (['ordered', 'preparing', 'ready'].includes(newStatus)) {
        console.log('Card not found, fetching order data for:', orderId)
        this.fetchAndAddOrder(orderId, newStatus)
      }
      return
    }
    
    // If status is delivered, billrequested, paid, or closed, remove from dashboard
    if (['delivered', 'billrequested', 'paid', 'closed'].includes(newStatus)) {
      orderCard.remove()
      return
    }
    
    // Update card status
    orderCard.dataset.status = newStatus
    
    // Update card header color
    const cardHeader = orderCard.querySelector('.card-header')
    if (cardHeader) {
      cardHeader.className = 'card-header py-2 d-flex justify-content-between align-items-center'
      if (newStatus === 'ordered') {
        cardHeader.classList.add('bg-danger-subtle')
      } else if (newStatus === 'preparing') {
        cardHeader.classList.add('bg-warning-subtle')
      } else if (newStatus === 'ready') {
        cardHeader.classList.add('bg-success-subtle')
      }
    }
    
    // Update button
    const cardFooter = orderCard.querySelector('.card-footer')
    if (cardFooter) {
      let buttonHtml = ''
      if (newStatus === 'ordered') {
        buttonHtml = '<button class="btn btn-warning w-100 order-status-btn" data-order-id="' + orderId + '" data-new-status="preparing"><i class="bi bi-play-fill"></i> Start Preparing</button>'
      } else if (newStatus === 'preparing') {
        buttonHtml = '<button class="btn btn-success w-100 order-status-btn" data-order-id="' + orderId + '" data-new-status="ready"><i class="bi bi-check-circle"></i> Mark Ready</button>'
      } else if (newStatus === 'ready') {
        buttonHtml = '<button class="btn btn-primary w-100 order-status-btn" data-order-id="' + orderId + '" data-new-status="delivered"><i class="bi bi-check2-all"></i> Mark as Collected</button>'
      }
      cardFooter.innerHTML = buttonHtml
    }
    
    // Move to new column
    const newColumnId = this.getColumnId(newStatus)
    const newColumn = document.getElementById(newColumnId)
    if (newColumn) {
      newColumn.appendChild(orderCard)
    }
  }
  
  getColumnId(status) {
    if (status === 'ordered') {
      return 'pending-orders'
    } else if (status === 'preparing') {
      return 'preparing-orders'
    } else if (status === 'ready') {
      return 'ready-orders'
    }
    return null
  }
  
  updateMetric(type, change) {
    const metricElement = document.getElementById(`${type}-count`)
    if (!metricElement) return
    
    const currentValue = parseInt(metricElement.textContent) || 0
    const newValue = Math.max(0, currentValue + change)
    metricElement.textContent = newValue
    
    // Add pulse animation
    metricElement.parentElement.classList.add('metric-updated')
    setTimeout(() => {
      metricElement.parentElement.classList.remove('metric-updated')
    }, 300)
  }
  
  updateColumnBadge(columnName) {
    const columnId = `${columnName}-orders`
    const column = document.getElementById(columnId)
    if (!column) return
    
    const count = column.querySelectorAll('.order-card').length
    const badge = column.closest('.card').querySelector('.badge')
    if (badge) {
      badge.textContent = count
    }
  }
  
  updateMetricsFromStatusChange(oldStatus, newStatus) {
    const oldColumn = this.getColumnType(oldStatus)
    const newColumn = this.getColumnType(newStatus)
    
    if (oldColumn) this.updateMetric(oldColumn, -1)
    if (newColumn) this.updateMetric(newColumn, 1)
    
    this.updateColumnBadge(oldColumn)
    this.updateColumnBadge(newColumn)
  }
  
  getColumnType(status) {
    if (status === 'ordered') return 'pending'
    if (status === 'preparing') return 'preparing'
    if (status === 'ready') return 'ready'
    return null
  }
  
  fetchAndAddOrder(orderId, status) {
    console.log(`Fetching order ${orderId} with status ${status}`)
    const columnType = this.getColumnType(status)
    console.log(`Column type for status ${status}: ${columnType}`)
    
    // Fetch order data from server
    fetch(`/restaurants/${this.restaurantId}/ordrs/${orderId}.json`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        console.log('Fetched order data:', data)
        console.log(`Overriding fetched status '${data.status}' with broadcast status '${status}'`)
        
        // IMPORTANT: Use the status from the broadcast, not the fetched data
        // The broadcast status is more current than the JSON response
        data.status = status
        
        console.log(`Adding to column type: ${columnType}`)
        // Create order card with fetched data
        this.addOrderToColumn(data, columnType)
        this.playNotificationSound()
        this.showNotification('New Order', `Order #${data.id} received`)
      })
      .catch(error => {
        console.error('Error fetching order:', error)
      })
  }
  
  createOrderCardElement(order) {
    console.log('Creating order card element for order:', order.id)
    const card = document.createElement('div')
    card.className = 'card mb-2 order-card shadow-sm'
    card.dataset.orderId = order.id
    card.dataset.status = order.status
    card.dataset.createdAt = Math.floor(new Date(order.created_at).getTime() / 1000)
    console.log('Card element created with dataset:', card.dataset)
    
    // Determine header color based on status
    let headerClass = 'bg-danger-subtle'
    if (order.status === 'preparing') headerClass = 'bg-warning-subtle'
    if (order.status === 'ready') headerClass = 'bg-success-subtle'
    
    // Build items HTML
    let itemsHtml = ''
    if (order.ordritems && order.ordritems.length > 0) {
      itemsHtml = order.ordritems.map(item => `
        <div class="list-group-item px-0 py-2 border-0">
          <div class="d-flex justify-content-between align-items-start">
            <div class="flex-grow-1">
              <strong>${item.menuitem ? item.menuitem.name : 'Item'}</strong>
            </div>
          </div>
        </div>
      `).join('')
    } else {
      itemsHtml = '<div class="list-group-item px-0 py-2 border-0">Loading items...</div>'
    }
    
    // Determine button based on status
    console.log(`Determining button for order ${order.id} with status: ${order.status}`)
    let buttonHtml = ''
    if (order.status === 'ordered') {
      buttonHtml = `<button class="btn btn-warning w-100 order-status-btn" data-order-id="${order.id}" data-new-status="preparing">
        <i class="bi bi-play-fill"></i> Start Preparing
      </button>`
    } else if (order.status === 'preparing') {
      buttonHtml = `<button class="btn btn-success w-100 order-status-btn" data-order-id="${order.id}" data-new-status="ready">
        <i class="bi bi-check-circle"></i> Mark Ready
      </button>`
    } else if (order.status === 'ready') {
      buttonHtml = `<button class="btn btn-primary w-100 order-status-btn" data-order-id="${order.id}" data-new-status="delivered">
        <i class="bi bi-check2-all"></i> Mark as Collected
      </button>`
    }
    console.log(`Button HTML generated: ${buttonHtml ? 'Yes' : 'No (empty)'}`)
    
    card.innerHTML = `
      <div class="card-header py-2 d-flex justify-content-between align-items-center ${headerClass}">
        <div>
          <strong class="fs-5">Order #${order.id}</strong>
          ${order.tablesetting ? `
            <span class="badge bg-secondary ms-2">
              <i class="bi bi-table"></i> ${order.tablesetting.name}
            </span>
          ` : ''}
        </div>
        <small class="text-muted">
          <i class="bi bi-clock"></i> Just now
        </small>
      </div>
      
      <div class="card-body py-2">
        <div class="list-group list-group-flush">
          ${itemsHtml}
        </div>
      </div>
      
      <div class="card-footer py-2 bg-white border-top">
        ${buttonHtml}
      </div>
    `
    
    return card
  }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new KitchenDashboard()
})

// Request notification permission
if ('Notification' in window && Notification.permission === 'default') {
  Notification.requestPermission()
}
