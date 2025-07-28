import consumer from "./consumer_with_reconnect"
import pako from "pako";

// Check if we're in a browser environment
const isBrowser = typeof window !== 'undefined' && typeof document !== 'undefined';

// Connection status element to show to users
const createConnectionStatusElement = () => {
  if (!isBrowser) return null;
  
  // Check if element already exists
  let statusEl = document.getElementById('connection-status');
  if (statusEl) return statusEl;
  
  // Create new element if it doesn't exist
  statusEl = document.createElement('div');
  statusEl.id = 'connection-status';
  statusEl.style.position = 'fixed';
  statusEl.style.bottom = '10px';
  statusEl.style.right = '10px';
  statusEl.style.padding = '10px 15px';
  statusEl.style.borderRadius = '4px';
  statusEl.style.zIndex = '9999';
  statusEl.style.transition = 'all 0.3s ease';
  statusEl.style.display = 'none';
  
  // Add to body if it exists
  if (document.body) {
    document.body.appendChild(statusEl);
  } else {
    document.addEventListener('DOMContentLoaded', () => {
      document.body.appendChild(statusEl);
    });
  }
  
  return statusEl;
};

const connectionStatus = isBrowser ? createConnectionStatusElement() : null;

const updateConnectionStatus = (status, message) => {
  if (!connectionStatus || !isBrowser) return;
  
  try {
    // Ensure the element is in the DOM
    if (!document.body.contains(connectionStatus) && document.body) {
      document.body.appendChild(connectionStatus);
    }
    
    connectionStatus.textContent = message;
    connectionStatus.style.display = 'block';
    
    // Clear previous classes
    connectionStatus.className = '';
    
    switch(status) {
      case 'connected':
        connectionStatus.style.backgroundColor = '#4CAF50';
        connectionStatus.style.color = 'white';
        // Hide after 3 seconds if connected
        setTimeout(() => {
          if (connectionStatus && connectionStatus.textContent === message) {
            connectionStatus.style.display = 'none';
          }
        }, 3000);
        break;
      case 'disconnected':
        connectionStatus.style.backgroundColor = '#f44336';
        connectionStatus.style.color = 'white';
        break;
      case 'reconnecting':
        connectionStatus.style.backgroundColor = '#FFC107';
        connectionStatus.style.color = 'black';
        break;
      case 'error':
        connectionStatus.style.backgroundColor = '#9C27B0';
        connectionStatus.style.color = 'white';
        break;
      default:
        connectionStatus.style.backgroundColor = '#9E9E9E';
        connectionStatus.style.color = 'white';
    }
  } catch (e) {
    console.error('Error updating connection status:', e);
  }
};

function decompressPartial(compressed) {
  if (!compressed || typeof compressed !== 'string') return '';
  const binaryString = window.atob(compressed);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return pako.inflate(bytes, { to: 'string' });
}

// Order status constants
const ORDER_STATUS = {
  OPENED: 0,
  ORDERED: 20,
  DELIVERED: 25,
  PAID: 30,
  CANCELED: 40,
  ARCHIVED: 50,
  DELETED: 60,
  CLOSED: 70,
  REFUNDED: 80,
  PARTIALLY_REFUNDED: 90,
  PARTIALLY_PAID: 100
};

// Order item status constants
const ORDER_ITEM_STATUS = {
  ADDED: 0,
  REMOVED: 10,
  ORDERED: 20,
  PREPARED: 30,
  DELIVERED: 40
};

function closeAllModals() {
  if (isBrowser && typeof $ !== 'undefined') {
    $('.modal').modal('hide');
    $('.modal-backdrop').remove();
  }
}

function refreshOrderJSLogic() {
  if (!isBrowser || !$ || !$("#smartmenu").is(':visible')) return;
  
  const date = new Date();
  const minutes = date.getMinutes();
  const hour = date.getHours();
  const currentOffset = (hour * 60) + minutes;
  
  $(".addItemToOrder").each(function() {
    const fromOffset = $(this).data('bs-menusection_from_offset');
    const toOffset = $(this).data('bs-menusection_to_offset');
    if (currentOffset < fromOffset || currentOffset > toOffset) {
      $(this).attr("disabled", "disabled");
    }
  });
  
  $('#toggleFilters').click(function() {
    $(':checkbox').prop('checked', this.checked);
  });
  
  $(".tipPreset").click(function() {
    const presetTipPercentage = parseFloat($(this).text());
    const gross = parseFloat($("#orderGross").text());
    const tip = ((gross / 100) * presetTipPercentage).toFixed(2);
    $("#tipNumberField").val(tip);
    const total = (parseFloat(tip) + parseFloat(gross)).toFixed(2);
    $("#orderGrandTotal").text($('#restaurantCurrency').text() + parseFloat(total).toFixed(2));
    $("#paymentAmount").val((parseFloat(total).toFixed(2) * 100));
    $("#paymentlink").text('');
    $("#paymentAnchor").prop("href", '');
    $("#paymentQR").empty();
  });
  
  $("#tipNumberField").on('change', function() {
    $(this).val(parseFloat($(this).val() || 0).toFixed(2));
    const gross = parseFloat($("#orderGross").text());
    const tip = parseFloat($(this).val() || 0);
    const total = tip + gross;
    $("#orderGrandTotal").text($('#restaurantCurrency').text() + total.toFixed(2));
  });
  
  if ($('#restaurantCurrency').length) {
    window.restaurantCurrencySymbol = $('#restaurantCurrency').text();
  }
  
  if ($('#addNameToParticipantModal').length) {
    const modal = document.getElementById('addNameToParticipantModal');
    modal.addEventListener('show.bs.modal', event => {
      // Handle modal show event
    });
    
    $("#addNameToParticipantButton").on("click", function() {
      // Handle participant name addition
    });
  }
}

// Initialize the order channel subscription
function initializeOrderChannel() {
  if (!isBrowser || !document.body) return null;
  
  const orderId = document.body.dataset.smartmenuId;
  if (!orderId) return null;
  
  let subscription = null;
  
  const subscribeToChannel = () => {
    if (subscription) {
      subscription.unsubscribe();
    }
    
    subscription = consumer.subscriptions.create(
      { channel: "OrdrChannel", order_id: orderId },
      {
        connected() {
          console.log('Connected to OrdrChannel');
          updateConnectionStatus('connected', 'Connected to server');
        },
        
        disconnected() {
          console.log('Disconnected from OrdrChannel');
          updateConnectionStatus('disconnected', 'Disconnected from server');
        },
        
        rejected() {
          console.error('Connection to OrdrChannel was rejected');
          updateConnectionStatus('error', 'Connection rejected');
        },
        
        received(data) {
          try {
            if (data.html) {
              // Handle HTML updates
              const element = document.querySelector(data.selector);
              if (element) {
                element.outerHTML = data.html;
              }
            } else if (data.partial) {
              // Handle partial updates
              const element = document.querySelector(data.selector);
              if (element) {
                element.outerHTML = decompressPartial(data.partial);
              }
            } else if (data.action === 'refresh') {
              // Handle refresh actions
              if (data.selector) {
                const element = document.querySelector(data.selector);
                if (element) {
                  element.innerHTML = data.content;
                }
              } else {
                window.location.reload();
              }
            }
            
            // Refresh any order-related logic
            refreshOrderJSLogic();
          } catch (error) {
            console.error('Error processing received data:', error);
            updateConnectionStatus('error', 'Error processing update');
          }
        }
      }
    );
    
    return subscription;
  };
  
  // Initial subscription
  subscribeToChannel();
  
  // Handle page visibility changes
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && consumer && !consumer.isConnected) {
      console.log('Page became visible, reconnecting...');
      if (consumer.connection && consumer.connection.monitor) {
        consumer.connection.monitor.start();
      }
    }
  });
  
  // Clean up on page unload
  window.addEventListener('beforeunload', () => {
    if (subscription) {
      subscription.unsubscribe();
    }
  });
  
  // Global error handler for the channel
  window.handleChannelError = (error) => {
    console.error('Channel error:', error);
    updateConnectionStatus('error', 'Connection error occurred');
    
    // Try to resubscribe if we're not already reconnecting
    if (consumer && !consumer.reconnectTimer) {
      console.log('Attempting to resubscribe after error...');
      if (subscription) {
        subscription.unsubscribe();
      }
      subscribeToChannel();
    }
  };
  
  return {
    unsubscribe: () => {
      if (subscription) {
        subscription.unsubscribe();
        subscription = null;
      }
    },
    resubscribe: subscribeToChannel
  };
}

// Initialize the order channel when the document is ready
if (isBrowser) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeOrderChannel);
  } else {
    initializeOrderChannel();
  }
}
