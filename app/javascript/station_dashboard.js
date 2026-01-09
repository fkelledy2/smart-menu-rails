// Station Dashboard - shared logic for Kitchen and Bar dashboards
// Loaded via javascript_include_tag (not an ES6 module)

class StationDashboard {
  constructor() {
    this.container = document.querySelector('.kitchen-dashboard');
    this.restaurantId = this.container?.dataset.restaurantId;
    this.station = this.container?.dataset.station;

    if (!this.restaurantId || !this.station) return;

    this.initializeClock();
    this.initializeStationChannel();
    this.initializePresenceChannel();
    this.initializeTicketStatusButtons();
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
      if (clockElement) clockElement.textContent = `${dateString} - ${timeString}`;
    };

    updateClock();
    setInterval(updateClock, 1000);
  }

  initializeStationChannel() {
    if (!window.App || !window.App.cable) {
      console.error('Action Cable not available');
      return;
    }

    this.stationChannel = window.App.cable.subscriptions.create(
      { channel: 'StationChannel', restaurant_id: this.restaurantId, station: this.station },
      {
        connected: () => {
          console.log('Station dashboard connected');
        },
        disconnected: () => {
          console.log('Station dashboard disconnected');
        },
        received: (data) => {
          this.handleStationMessage(data);
        },
      }
    );
  }

  initializePresenceChannel() {
    if (!window.App || !window.App.cable) return;

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
        received: (data) => {
          this.handlePresenceMessage(data);
        },
      }
    );
  }

  handlePresenceMessage(data) {
    if (!data || !data.user_id) return;

    const userId = String(data.user_id);
    const prev = this.presenceState.get(userId);

    this.presenceState.set(userId, {
      user_id: userId,
      email: data.email,
      status: data.status,
      event: data.event,
      timestamp: data.timestamp,
    });

    if (prev && prev.status === data.status && prev.event === data.event) return;
    this.renderPresence();
  }

  renderPresence() {
    const countEl = document.getElementById('kitchen-presence-count');
    const listEl = document.getElementById('kitchen-presence-list');
    if (!countEl || !listEl) return;

    const users = Array.from(this.presenceState.values()).filter((u) => u.status && u.status !== 'offline');
    countEl.textContent = String(users.length);

    listEl.innerHTML = users
      .slice(0, 5)
      .map((u) => {
        const label = (u.email || '').split('@')[0] || `User ${u.user_id}`;
        const badgeClass = u.status === 'active' ? 'bg-success' : 'bg-warning text-dark';
        const statusLabel = u.status === 'active' ? 'active' : 'idle';
        return `<span class="badge ${badgeClass} me-1">${label} • ${statusLabel}</span>`;
      })
      .join('');
  }

  handleStationMessage(data) {
    if (!data || !data.event || !data.ticket) return;

    if (data.event === 'new_ticket') {
      this.addTicketToColumn(data.ticket, this.getColumnType(data.ticket.status));
      this.updateMetric(this.getColumnType(data.ticket.status), 1);
      return;
    }

    if (data.event === 'status_change') {
      this.moveTicketBetweenColumns(data.ticket.id, data.old_status, data.new_status, data.ticket);
      this.updateMetricsFromStatusChange(data.old_status, data.new_status);
    }
  }

  initializeTicketStatusButtons() {
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.ticket-status-btn');
      if (!button) return;

      const ticketId = button.dataset.ticketId;
      const newStatus = button.dataset.newStatus;
      if (!ticketId || !newStatus) return;

      this.updateTicketStatus(ticketId, newStatus);
    });
  }

  updateTicketStatus(ticketId, newStatus) {
    fetch(`/restaurants/${this.restaurantId}/ordr_station_tickets/${ticketId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        Accept: 'application/json',
      },
      body: JSON.stringify({ ordr_station_ticket: { status: newStatus } }),
    }).catch((error) => {
      console.error('Error updating ticket status:', error);
      alert('Failed to update ticket status');
    });
  }

  initializeSortButtons() {
    document.addEventListener('click', (event) => {
      const button = event.target.closest('.sort-toggle-btn');
      if (!button) return;

      const column = button.dataset.column;
      const currentDirection = button.dataset.direction;
      const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
      button.dataset.direction = newDirection;

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
      return direction === 'asc' ? timeA - timeB : timeB - timeA;
    });

    column.innerHTML = '';
    if (emptyState) column.appendChild(emptyState);
    cards.forEach((card) => column.appendChild(card));

    this.updateEmptyState(columnName);
  }

  addTicketToColumn(ticket, columnType) {
    const columnId = `${columnType}-orders`;
    const column = document.getElementById(columnId);
    if (!column) return;

    const card = this.createTicketCardElement(ticket);
    const emptyState = column.querySelector(`.empty-state[data-empty-for="${columnType}"]`);

    if (emptyState) {
      emptyState.insertAdjacentElement('afterend', card);
    } else {
      column.insertBefore(card, column.firstChild);
    }

    this.updateColumnBadge(columnType);
    this.updateEmptyState(columnType);
  }

  moveTicketBetweenColumns(ticketId, oldStatus, newStatus, ticket) {
    const oldColumnType = this.getColumnType(oldStatus);
    const newColumnType = this.getColumnType(newStatus);

    const card = document.querySelector(`.order-card[data-ticket-id="${ticketId}"]`);
    if (!card) {
      // If missing, just insert fresh
      this.addTicketToColumn(ticket, newColumnType);
      return;
    }

    card.dataset.status = newStatus;

    const header = card.querySelector('.card-header');
    if (header) {
      header.className = 'card-header py-2 d-flex justify-content-between align-items-center';
      if (newStatus === 'ordered') header.classList.add('bg-danger-subtle');
      if (newStatus === 'preparing') header.classList.add('bg-warning-subtle');
      if (newStatus === 'ready') header.classList.add('bg-success-subtle');
    }

    const footer = card.querySelector('.card-footer');
    if (footer) {
      let html = '';
      if (newStatus === 'ordered') {
        html = `<button class="btn btn-warning w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="preparing">Start Preparing</button>`;
      } else if (newStatus === 'preparing') {
        html = `<button class="btn btn-success w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="ready">Mark Ready</button>`;
      } else if (newStatus === 'ready') {
        html = `<button class="btn btn-primary w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="collected">Mark as Collected</button>`;
      }
      footer.innerHTML = html;
    }

    if (!newColumnType) {
      card.remove();
    } else {
      const newColumn = document.getElementById(`${newColumnType}-orders`);
      if (newColumn) newColumn.appendChild(card);
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

  updateEmptyState(columnType) {
    const column = document.getElementById(`${columnType}-orders`);
    if (!column) return;

    const emptyState = column.querySelector(`.empty-state[data-empty-for="${columnType}"]`);
    if (!emptyState) return;

    const hasCards = column.querySelectorAll('.order-card').length > 0;
    emptyState.style.display = hasCards ? 'none' : '';
  }

  updateColumnBadge(columnName) {
    if (!columnName) return;

    const column = document.getElementById(`${columnName}-orders`);
    if (!column) return;

    const count = column.querySelectorAll('.order-card').length;
    const badge = column.closest('.card').querySelector('.badge');
    if (badge) badge.textContent = count;
  }

  updateMetric(type, change) {
    const metricElement = document.getElementById(`${type}-count`);
    if (!metricElement) return;

    const currentValue = parseInt(metricElement.textContent) || 0;
    const newValue = Math.max(0, currentValue + change);
    metricElement.textContent = newValue;
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

  createTicketCardElement(ticket) {
    const card = document.createElement('div');
    card.className = 'card mb-2 order-card shadow-sm';
    card.dataset.ticketId = ticket.id;
    card.dataset.orderId = ticket.order_id;
    card.dataset.status = ticket.status;
    card.dataset.createdAt = Math.floor(new Date(ticket.created_at).getTime() / 1000);

    let headerClass = 'bg-danger-subtle';
    if (ticket.status === 'preparing') headerClass = 'bg-warning-subtle';
    if (ticket.status === 'ready') headerClass = 'bg-success-subtle';

    const itemsHtml = (ticket.items || [])
      .map((i) => {
        const notes = (i.notes || []).length ? `<div class="text-muted small">${i.notes.join(', ')}</div>` : '';
        return `<li>${i.name || 'Item'}${notes}</li>`;
      })
      .join('');

    let buttonHtml = '';
    if (ticket.status === 'ordered') {
      buttonHtml = `<button class="btn btn-warning w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="preparing">Start Preparing</button>`;
    } else if (ticket.status === 'preparing') {
      buttonHtml = `<button class="btn btn-success w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="ready">Mark Ready</button>`;
    } else if (ticket.status === 'ready') {
      buttonHtml = `<button class="btn btn-primary w-100 ticket-status-btn" data-ticket-id="${ticket.id}" data-new-status="collected">Mark as Collected</button>`;
    }

    card.innerHTML = `
      <div class="card-header py-2 d-flex justify-content-between align-items-center ${headerClass}">
        <div>
          <strong class="fs-5">Order #${ticket.order_id}</strong>
          ${ticket.table ? `<span class="badge bg-secondary ms-2">${ticket.table}</span>` : ''}
        </div>
        <small class="text-muted"><i class="bi bi-clock"></i> Just now</small>
      </div>
      <div class="card-body py-2">
        <ul class="mb-0">${itemsHtml}</ul>
      </div>
      <div class="card-footer py-2 bg-white border-top">${buttonHtml}</div>
    `;

    return card;
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new StationDashboard();
});

if ('Notification' in window && Notification.permission === 'default') {
  Notification.requestPermission();
}
