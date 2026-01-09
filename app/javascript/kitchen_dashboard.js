// Kitchen Dashboard - Real-time order management for large screen displays
// Note: This file is loaded via javascript_include_tag, not as an ES6 module

class KitchenDashboard {
  constructor() {
    this.restaurantId = document.querySelector('.kitchen-dashboard')?.dataset.restaurantId;
    if (!this.restaurantId) return;

    this.initializeClock();
    this.initializeKitchenChannel();
    this.initializePresenceChannel();
    this.initializeNotificationSound();
    this.initializeOrderStatusButtons();
    this.initializeSortButtons();
  }

  initializeClock() {
    const updateClock = () => {
      const now = new Date();
      const timeString = now.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      });
      const dateString = now.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      const clockElement = document.getElementById('current-time');
      if (clockElement) {
        clockElement.textContent = `${dateString} - ${timeString}`;
      }
    };

    updateClock();
    setInterval(updateClock, 1000);
  }

  initializeKitchenChannel() {
    // Access the global App.cable consumer
    if (!window.App || !window.App.cable) {
      console.error('Action Cable not available');
      return;
    }

    this.kitchenChannel = window.App.cable.subscriptions.create(
      { channel: 'KitchenChannel', restaurant_id: this.restaurantId },
      {
        connected: () => {
          console.log('Kitchen dashboard connected');
          this.showConnectionStatus(true);
        },

        disconnected: () => {
          console.log('Kitchen dashboard disconnected');
          this.showConnectionStatus(false);
        },

        received: (data) => {
          console.log('Kitchen update received:', data);
          this.handleKitchenMessage(data);
        },
      }
    );
  }

  initializePresenceChannel() {
    if (!window.App || !window.App.cable) {
      return;
    }

    this.presenceState = new Map();

    this.presenceChannel = window.App.cable.subscriptions.create(
      {
        channel: 'PresenceChannel',
        resource_type: 'Restaurant',
        resource_id: this.restaurantId,
      },
      {
        connected: () => {
          this.renderPresence();
        },
        disconnected: () => {
          // Keep the last known state rendered; no-op
        },
        received: (data) => {
          this.handlePresenceMessage(data);
        },
      }
    );

    // Activity / idle tracking
    this.attachPresenceActivityListeners();
  }

  attachPresenceActivityListeners() {
    const pingAppear = () => {
      try {
        if (this.presenceChannel) {
          this.presenceChannel.perform('appear');
        }
      } catch (_) {}
    };

    // Basic user activity signals
    ['mousemove', 'keydown', 'click', 'touchstart'].forEach((evt) => {
      document.addEventListener(evt, this.debounce(pingAppear, 1000), { passive: true });
    });

    // Periodic heartbeat to keep sessions fresh on wall displays
    this.presenceHeartbeatTimer = setInterval(() => {
      pingAppear();
    }, 60 * 1000);

    // Idle detection
    if (this.idleTimer) {
      clearTimeout(this.idleTimer);
    }
    const resetIdleTimer = () => {
      if (this.idleTimer) clearTimeout(this.idleTimer);
      this.idleTimer = setTimeout(() => {
        try {
          if (this.presenceChannel) {
            this.presenceChannel.perform('away');
          }
        } catch (_) {}
      }, 5 * 60 * 1000);
    };
    resetIdleTimer();
    ['mousemove', 'keydown', 'click', 'touchstart'].forEach((evt) => {
      document.addEventListener(evt, this.debounce(resetIdleTimer, 1000), { passive: true });
    });
  }

  handlePresenceMessage(data) {
    // Expect payload from PresenceService
    if (!data || !data.user_id) return;

    const userId = String(data.user_id);
    const prev = this.presenceState.get(userId);

    // Store most recent event for user
    this.presenceState.set(userId, {
      user_id: userId,
      email: data.email,
      status: data.status,
      event: data.event,
      timestamp: data.timestamp,
    });

    // Avoid excessive re-render if nothing changed
    if (prev && prev.status === data.status && prev.event === data.event) return;
    this.renderPresence();
  }

  renderPresence() {
    const countEl = document.getElementById('kitchen-presence-count');
    const listEl = document.getElementById('kitchen-presence-list');
    if (!countEl || !listEl) return;

    const users = Array.from(this.presenceState.values())
      .filter((u) => u.status && u.status !== 'offline')
      .sort((a, b) => {
        const sa = a.status || '';
        const sb = b.status || '';
        // active first, then idle
        const rank = (s) => (s === 'active' ? 0 : s === 'idle' ? 1 : 2);
        return rank(sa) - rank(sb);
      });

    countEl.textContent = String(users.length);

    // Show a short list of emails with status badges
    listEl.innerHTML = users
      .slice(0, 5)
      .map((u) => {
        const label = (u.email || '').split('@')[0] || `User ${u.user_id}`;
        const badgeClass = u.status === 'active' ? 'bg-success' : 'bg-warning text-dark';
        const statusLabel = u.status === 'active' ? 'active' : 'idle';
        return `<span class="badge ${badgeClass} me-1">${label} • ${statusLabel}</span>`;
      })
      .join('');

    if (users.length > 5) {
      listEl.insertAdjacentHTML(
        'beforeend',
        `<span class="ms-1">+${users.length - 5} more</span>`
      );
    }
  }

  debounce(fn, waitMs) {
    let t = null;
    return (...args) => {
      if (t) clearTimeout(t);
      t = setTimeout(() => fn(...args), waitMs);
    };
  }

  handleKitchenMessage(data) {
    switch (data.event) {
      case 'new_order':
        console.log('New order received:', data.order);
        this.addOrderToColumn(data.order, 'pending');
        this.updateMetric('pending', 1);
        this.playNotificationSound();
        this.showNotification('New Order', `Order #${data.order.id} received`);
        break;
      case 'status_change':
        console.log('Order status changed:', data);
        this.moveOrderBetweenColumns(data.order_id, data.old_status, data.new_status);
        this.updateMetricsFromStatusChange(data.old_status, data.new_status);
        break;
      case 'queue_update':
        console.log('Queue updated:', data);
        this.updateMetric('pending', data.queue_length);
        break;
    }
  }

  initializeNotificationSound() {
    // Create a simple beep sound using Web Audio API
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }

  initializeOrderStatusButtons() {
    // Use event delegation for dynamically added order cards
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.order-status-btn');
      if (!button) return;

      const orderId = button.dataset.orderId;
      const newStatus = button.dataset.newStatus;

      if (orderId && newStatus) {
        this.updateOrderStatus(orderId, newStatus);
      }
    });
  }

  updateOrderStatus(orderId, newStatus) {
    fetch(`/restaurants/${this.restaurantId}/ordrs/${orderId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify({
        ordr: { status: newStatus },
      }),
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then((data) => {
        console.log('Order updated:', data);
      })
      .catch((error) => {
        console.error('Error updating order:', error);
        alert('Failed to update order status');
      });
  }

  initializeSortButtons() {
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.sort-toggle-btn');
      if (!button) return;

      const column = button.dataset.column;
      const currentDirection = button.dataset.direction;

      // Toggle direction
      const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
      button.dataset.direction = newDirection;

      // Update icon
      const icon = button.querySelector('i');
      if (newDirection === 'asc') {
        icon.className = 'bi bi-sort-up';
        button.title = 'Sort: Oldest First';
      } else {
        icon.className = 'bi bi-sort-down';
        button.title = 'Sort: Newest First';
      }

      this.sortColumn(column, newDirection);
    });
  }

  sortColumn(columnName, direction) {
    const columnId = `${columnName}-orders`;
    const column = document.getElementById(columnId);
    if (!column) return;

    const emptyState = column.querySelector('.empty-state');
    const cards = Array.from(column.querySelectorAll('.order-card'));

    cards.sort((a, b) => {
      const timeA = parseInt(a.dataset.createdAt);
      const timeB = parseInt(b.dataset.createdAt);

      if (direction === 'asc') {
        return timeA - timeB; // Oldest first
      } else {
        return timeB - timeA; // Newest first
      }
    });

    // Clear and re-append sorted cards
    column.innerHTML = '';
    if (emptyState) column.appendChild(emptyState);
    cards.forEach((card) => column.appendChild(card));

    if (columnName) {
      this.updateEmptyState(columnName);
    }
  }

  playNotificationSound() {
    try {
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      oscillator.frequency.value = 800;
      oscillator.type = 'sine';

      gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.5);

      oscillator.start(this.audioContext.currentTime);
      oscillator.stop(this.audioContext.currentTime + 0.5);
    } catch (error) {
      console.error('Error playing notification sound:', error);
    }
  }

  showNotification(title, message) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        body: message,
        icon: '/icons/smart-menu-192.png',
      });
    }
  }

  addOrderToColumn(order, columnType) {
    // columnType is 'pending', 'preparing', or 'ready'
    const columnId = `${columnType}-orders`;
    const column = document.getElementById(columnId);

    if (!column) {
      console.error(`Column not found: ${columnId}`);
      return;
    }

    console.log(`Adding order ${order.id} to column ${columnId}`);

    // Create order card HTML
    const orderCard = this.createOrderCardElement(order);
    orderCard.classList.add('new-order');

    // Insert after empty-state if present, otherwise at top
    const emptyState = column.querySelector(`.empty-state[data-empty-for="${columnType}"]`);
    if (emptyState) {
      emptyState.insertAdjacentElement('afterend', orderCard);
    } else {
      column.insertBefore(orderCard, column.firstChild);
    }

    this.updateColumnBadge(columnType);
    this.updateEmptyState(columnType);

    // Remove new-order animation after 3 seconds
    setTimeout(() => {
      orderCard.classList.remove('new-order');
    }, 3000);
  }

  updateEmptyState(columnType) {
    const columnId = `${columnType}-orders`;
    const column = document.getElementById(columnId);
    if (!column) return;

    const emptyState = column.querySelector(`.empty-state[data-empty-for="${columnType}"]`);
    if (!emptyState) return;

    const hasOrders = column.querySelectorAll('.order-card').length > 0;
    emptyState.style.display = hasOrders ? 'none' : '';
  }

  moveOrderBetweenColumns(orderId, oldStatus, newStatus) {
    const oldColumnType = this.getColumnType(oldStatus);
    const newColumnType = this.getColumnType(newStatus);
    const orderCard = document.querySelector(`[data-order-id="${orderId}"]`);

    // If card doesn't exist and new status is kitchen-relevant, fetch and create it
    if (!orderCard) {
      if (['ordered', 'preparing', 'ready'].includes(newStatus)) {
        console.log('Card not found, fetching order data for:', orderId);
        this.fetchAndAddOrder(orderId, newStatus);
      }
      return;
    }

    // If status is delivered, billrequested, paid, or closed, remove from dashboard
    if (['delivered', 'billrequested', 'paid', 'closed'].includes(newStatus)) {
      orderCard.remove();

      if (oldColumnType) {
        this.updateColumnBadge(oldColumnType);
        this.updateEmptyState(oldColumnType);
      }
      return;
    }

    // Update card status
    orderCard.dataset.status = newStatus;

    // Update card header color
    const cardHeader = orderCard.querySelector('.card-header');
    if (cardHeader) {
      cardHeader.className = 'card-header py-2 d-flex justify-content-between align-items-center';
      if (newStatus === 'ordered') {
        cardHeader.classList.add('bg-danger-subtle');
      } else if (newStatus === 'preparing') {
        cardHeader.classList.add('bg-warning-subtle');
      } else if (newStatus === 'ready') {
        cardHeader.classList.add('bg-success-subtle');
      }
    }

    // Update button
    const cardFooter = orderCard.querySelector('.card-footer');
    if (cardFooter) {
      let buttonHtml = '';
      if (newStatus === 'ordered') {
        buttonHtml =
          '<button class="btn btn-warning w-100 order-status-btn" data-order-id="' +
          orderId +
          '" data-new-status="preparing"><i class="bi bi-play-fill"></i> Start Preparing</button>';
      } else if (newStatus === 'preparing') {
        buttonHtml =
          '<button class="btn btn-success w-100 order-status-btn" data-order-id="' +
          orderId +
          '" data-new-status="ready"><i class="bi bi-check-circle"></i> Mark Ready</button>';
      } else if (newStatus === 'ready') {
        buttonHtml =
          '<button class="btn btn-primary w-100 order-status-btn" data-order-id="' +
          orderId +
          '" data-new-status="delivered"><i class="bi bi-check2-all"></i> Mark as Collected</button>';
      }
      cardFooter.innerHTML = buttonHtml;
    }

    // Move to new column
    const newColumnId = this.getColumnId(newStatus);
    const newColumn = document.getElementById(newColumnId);
    if (newColumn) {
      newColumn.appendChild(orderCard);
    }

    if (oldColumnType) {
      this.updateColumnBadge(oldColumnType);
      this.updateEmptyState(oldColumnType);
    }
    if (newColumnType) {
      this.updateColumnBadge(newColumnType);
      this.updateEmptyState(newColumnType);
    }
  }

  getColumnId(status) {
    if (status === 'ordered') {
      return 'pending-orders';
    } else if (status === 'preparing') {
      return 'preparing-orders';
    } else if (status === 'ready') {
      return 'ready-orders';
    }
    return null;
  }

  updateMetric(type, change) {
    const metricElement = document.getElementById(`${type}-count`);
    if (!metricElement) return;

    const currentValue = parseInt(metricElement.textContent) || 0;
    const newValue = Math.max(0, currentValue + change);
    metricElement.textContent = newValue;

    // Add pulse animation
    metricElement.parentElement.classList.add('metric-updated');
    setTimeout(() => {
      metricElement.parentElement.classList.remove('metric-updated');
    }, 300);
  }

  updateColumnBadge(columnName) {
    const columnId = `${columnName}-orders`;
    const column = document.getElementById(columnId);
    if (!column) return;

    const count = column.querySelectorAll('.order-card').length;
    const badge = column.closest('.card').querySelector('.badge');
    if (badge) {
      badge.textContent = count;
    }
  }

  updateMetricsFromStatusChange(oldStatus, newStatus) {
    const oldColumn = this.getColumnType(oldStatus);
    const newColumn = this.getColumnType(newStatus);

    if (oldColumn) this.updateMetric(oldColumn, -1);
    if (newColumn) this.updateMetric(newColumn, 1);

    this.updateColumnBadge(oldColumn);
    this.updateColumnBadge(newColumn);
  }

  getColumnType(status) {
    if (status === 'ordered') return 'pending';
    if (status === 'preparing') return 'preparing';
    if (status === 'ready') return 'ready';
    return null;
  }

  fetchAndAddOrder(orderId, status) {
    console.log(`Fetching order ${orderId} with status ${status}`);
    const columnType = this.getColumnType(status);
    console.log(`Column type for status ${status}: ${columnType}`);

    // Fetch order data from server
    fetch(`/restaurants/${this.restaurantId}/ordrs/${orderId}.json`)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then((data) => {
        console.log('Fetched order data:', data);
        console.log(`Overriding fetched status '${data.status}' with broadcast status '${status}'`);

        // IMPORTANT: Use the status from the broadcast, not the fetched data
        // The broadcast status is more current than the JSON response
        data.status = status;

        console.log(`Adding to column type: ${columnType}`);
        // Create order card with fetched data
        this.addOrderToColumn(data, columnType);
        this.playNotificationSound();
        this.showNotification('New Order', `Order #${data.id} received`);
      })
      .catch((error) => {
        console.error('Error fetching order:', error);
      });
  }

  createOrderCardElement(order) {
    console.log('Creating order card element for order:', order.id);
    const card = document.createElement('div');
    card.className = 'card mb-2 order-card shadow-sm';
    card.dataset.orderId = order.id;
    card.dataset.status = order.status;
    card.dataset.createdAt = Math.floor(new Date(order.created_at).getTime() / 1000);
    console.log('Card element created with dataset:', card.dataset);

    // Determine header color based on status
    let headerClass = 'bg-danger-subtle';
    if (order.status === 'preparing') headerClass = 'bg-warning-subtle';
    if (order.status === 'ready') headerClass = 'bg-success-subtle';

    // Build items HTML as bullet list
    let itemsHtml = '';
    if (order.ordritems && order.ordritems.length > 0) {
      itemsHtml = order.ordritems
        .map(
          (item) => `
        <li>${item.menuitem ? item.menuitem.name : 'Item'}</li>
      `
        )
        .join('');
    } else {
      itemsHtml = '<li>Loading items...</li>';
    }

    // Determine button based on status
    console.log(`Determining button for order ${order.id} with status: ${order.status}`);
    let buttonHtml = '';
    if (order.status === 'ordered') {
      buttonHtml = `<button class="btn btn-warning w-100 order-status-btn" data-order-id="${order.id}" data-new-status="preparing">
        <i class="bi bi-play-fill"></i> Start Preparing
      </button>`;
    } else if (order.status === 'preparing') {
      buttonHtml = `<button class="btn btn-success w-100 order-status-btn" data-order-id="${order.id}" data-new-status="ready">
        <i class="bi bi-check-circle"></i> Mark Ready
      </button>`;
    } else if (order.status === 'ready') {
      buttonHtml = `<button class="btn btn-primary w-100 order-status-btn" data-order-id="${order.id}" data-new-status="delivered">
        <i class="bi bi-check2-all"></i> Mark as Collected
      </button>`;
    }
    console.log(`Button HTML generated: ${buttonHtml ? 'Yes' : 'No (empty)'}`);

    card.innerHTML = `
      <div class="card-header py-2 d-flex justify-content-between align-items-center ${headerClass}">
        <div>
          <strong class="fs-5">Order #${order.id}</strong>
          ${
            order.tablesetting
              ? `
            <span class="badge bg-secondary ms-2">
              ${order.tablesetting.name}
            </span>
          `
              : ''
          }
        </div>
        <small class="text-muted">
          <i class="bi bi-clock"></i> Just now
        </small>
      </div>
      
      <div class="card-body py-2">
        <ul class="mb-0">
          ${itemsHtml}
        </ul>
      </div>
      
      <div class="card-footer py-2 bg-white border-top">
        ${buttonHtml}
      </div>
    `;

    return card;
  }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new KitchenDashboard();
});

// Request notification permission
if ('Notification' in window && Notification.permission === 'default') {
  Notification.requestPermission();
}
