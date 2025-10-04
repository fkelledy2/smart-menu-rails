import consumer from "./consumer"
import pako from 'pako';

    function post( url, body ) {
      $('#orderCart').hide();
      $('#orderCartSpinner').show();      
        fetch(url, {
            method: 'POST',
            headers:  {
                  "Content-Type": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            },
            body: JSON.stringify(body)
        }).then(response => {
        }).catch(function(err) {
            console.info(err + " url: " + url);
        });
        return false;
    }
    function patch( url, body ) {
      $('#orderCart').hide();
      $('#orderCartSpinner').show();      
        fetch(url, {
            method: 'PATCH',
            headers:  {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            },
            body: JSON.stringify(body)
        }).then(response => {
        }).catch(function(err) {
            console.info(err + " url: " + url);
        });
        return false;
    }

function fetchQR(paymentLink) {
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent(paymentLink)}`;
  const qrCodeImg = document.createElement('img');
  qrCodeImg.src = qrCodeUrl;
  qrCodeImg.alt = 'QR Code';

  const qrContainer = document.getElementById('paymentQR');
  if (qrContainer) {
    qrContainer.innerHTML = '';
    qrContainer.appendChild(qrCodeImg);
  }
}

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
  statusEl.style.top = '5px';
  statusEl.style.right = '5px';
  statusEl.style.padding = '5px 10px';
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
  try {
    // Decode the Base64 string to a binary string
    const binaryString = window.atob(compressed);
    const len = binaryString.length;
    // Convert the binary string to a Uint8Array
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    // Decompress using pako (which handles zlib format)
    const decompressed = pako.inflate(bytes, { to: 'string' });
    return decompressed;
  } catch (error) {
    console.error('Error decompressing partial:', error);
    return '';
  }
}

let ORDR_OPENED=0;
let ORDR_ORDERED=20;
let ORDR_BILLREQUESTED=30;
let ORDR_CLOSED=40;

let ORDRITEM_ADDED=0;
let ORDRITEM_REMOVED=10;

function closeAllModals() {
  if (isBrowser && typeof $ !== 'undefined') {
    $('.modal').modal('hide');
    $('.modal-backdrop').remove();
  }
}

function refreshOrderJSLogic() {

    const searchInput = document.getElementById("menu-item-search");
    if (!searchInput) return;

    searchInput.addEventListener("input", function() {
        const term = searchInput.value.trim().toLowerCase();
        if (term.length === 0) {
          // If search is empty, show all items
          document.querySelectorAll(".menu-item-card").forEach(card => card.style.display = "");
          return;
        }

        document.querySelectorAll(".menu-item-card").forEach(function(card) {
          // Search in data attributes (original English text)
          const name = card.getAttribute("data-name") || "";
          const desc = card.getAttribute("data-description") || "";

          // Search in visible text content (localized text)
          const cardText = card.textContent.toLowerCase();

          if (name.includes(term) || desc.includes(term) || cardText.includes(term)) {
            card.style.display = "";
          } else {
            card.style.display = "none";
          }
        });
    });

    if ($("#smartmenu").length) {
        var date = new Date;
        var minutes = date.getMinutes();
        var hour = date.getHours();
        var sectionFromOffset = parseInt($("#sectionFromOffset").html());
        var sectionToOffset = parseInt($("#sectionToOffset").html());
        var currentOffset = (hour*60)+minutes;
        $( ".addItemToOrder" ).each(function() {
            const fromOffeset = $(this).data('bs-menusection_from_offset');
            const toOffeset = $(this).data('bs-menusection_to_offset');
            if( currentOffset >= fromOffeset && currentOffset <= toOffeset ) {
            } else {
                $(this).attr("disabled","disabled");
            }
        });
    }
    $('#toggleFilters').click (function () {
      $(':checkbox').prop('checked', this.checked);
    });
    $(".tipPreset").click(function() {
        let presetTipPercentage = parseFloat($(this).text());
        let gross = parseFloat($("#orderGross").text());
        let tip = ((gross / 100) * presetTipPercentage).toFixed(2);
        $("#tipNumberField").val(tip);
        let total = parseFloat(parseFloat(tip)+parseFloat(gross)).toFixed(2);
        $("#orderGrandTotal").text($('#restaurantCurrency').text()+parseFloat(total).toFixed(2));
        $("#paymentAmount").val((parseFloat(total).toFixed(2)*100));
        $("#paymentlink").text('');
        $("#paymentAnchor").prop("href", '');
        $("#paymentQR").html('');
        $("#paymentQR").text('');
    });
    $("#tipNumberField").change(function() {
        $(this).val(parseFloat($(this).val()).toFixed(2));
        let gross = parseFloat($("#orderGross").text());
        let tip = parseFloat($(this).val());
        let total = tip+gross;
        $("#orderGrandTotal").text($('#restaurantCurrency').text()+parseFloat(total).toFixed(2));
    });
    let restaurantCurrencySymbol = '$';
    if ($('#restaurantCurrency').length) {
        restaurantCurrencySymbol = $('#restaurantCurrency').text();
    }
    if ($('#addNameToParticipantModal').length) {
        const addNameToParticipantModal = document.getElementById('addNameToParticipantModal');
        addNameToParticipantModal.addEventListener('show.bs.modal', event => {
            const button = event.relatedTarget
        });
        $( "#addNameToParticipantButton" ).on( "click", function(event) {
           let ordrparticipant = {
            'ordrparticipant': {
                'name': addNameToParticipantModal.querySelector('#name').value,
            }
           };
           patch( '/ordrparticipants/'+$('#currentParticipant').text(), ordrparticipant );
           event.preventDefault();
        });
    }
    $( ".setparticipantlocale" ).on( "click", function(event) {
       var locale = $(this).data('locale')
       if( $('#currentParticipant').text() ) {
           let ordrparticipant = {
                 'ordrparticipant': {
                     'preferredlocale': locale
                 }
           };
           patch( '/ordrparticipants/'+$('#currentParticipant').text(), ordrparticipant);
       }
       if( $('#menuParticipant').text() ) {
           let menuparticipant = {
                 'menuparticipant': {
                     'preferredlocale': locale
                 }
            };
           patch( '/menuparticipants/'+$('#menuParticipant').text(), menuparticipant);
       }
       event.preventDefault();
    });
    $( ".removeItemFromOrderButton" ).on( "click", function(event) {
       var ordrItemId = $(this).attr('data-bs-ordritem_id');
       let ordritem = {
         'ordritem': {
             'status': ORDRITEM_REMOVED,
             'ordritemprice': 0
         }
       };
       const restaurantId = $('#currentRestaurant').text();
       patch( `/restaurants/${restaurantId}/ordritems/${ordrItemId}`, ordritem);
       $('#confirm-order').click();
       return true;
    });
    var a2oMenuitemImage = document.getElementById("a2o_menuitem_image");
    if( a2oMenuitemImage ) {
        a2oMenuitemImage.addEventListener('load', function () {
            document.getElementById('spinner').style.display = 'none';
            document.getElementById('placeholder').style.display = 'none';
            this.style.opacity = 1;
        });
    }
    if ($('#addItemToOrderModal').length) {
        const addItemToOrderModal = document.getElementById('addItemToOrderModal');
        addItemToOrderModal.addEventListener('show.bs.modal', event => {
            const button = event.relatedTarget
            $('#a2o_ordr_id').text(button.getAttribute('data-bs-ordr_id'));
            $('#a2o_menuitem_id').text(button.getAttribute('data-bs-menuitem_id'));
            $('#a2o_menuitem_name').text(button.getAttribute('data-bs-menuitem_name'));
            $('#a2o_menuitem_price').text(parseFloat(button.getAttribute('data-bs-menuitem_price')).toFixed(2));
            $('#a2o_menuitem_description').text(button.getAttribute('data-bs-menuitem_description'));
            try {
                const imageElement = addItemToOrderModal.querySelector('#a2o_menuitem_image');
                if (imageElement) {
                    imageElement.src = button.getAttribute('data-bs-menuitem_image');
                    imageElement.alt = button.getAttribute('data-bs-menuitem_name');
                }
            } catch( err ) {
                alert( err );
            }
        });
        $( "#addItemToOrderButton" ).on( "click", function() {
            let ordritem = {
                'ordritem': {
                    'ordr_id': $('#a2o_ordr_id').text(),
                    'menuitem_id': $('#a2o_menuitem_id').text(),
                    'status': ORDRITEM_ADDED,
                    'ordritemprice': $('#a2o_menuitem_price').text()
                }
            };
            const restaurantId = $('#currentRestaurant').text();
            post( `/restaurants/${restaurantId}/ordritems`, ordritem, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            return true;
        });
    }
    if ($('#start-order').length) {
       $( "#start-order" ).on( "click", function() {
            const ordercapacity = document.getElementById('orderCapacity').value;
            if ($('#currentEmployee').length) {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'employee_id': $('#currentEmployee').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'ordercapacity': ordercapacity,
                      'status' : ORDR_OPENED
                    }
                };
                post( '/ordrs', ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'ordercapacity': ordercapacity,
                      'status' : ORDR_OPENED
                    }
                };
                post( '/ordrs', ordr );
            }
       });
    }
    if ($('#confirm-order').length) {
       $( "#confirm-order" ).on( "click", function() {
            if ($('#currentEmployee').length) {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'employee_id': $('#currentEmployee').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_ORDERED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_ORDERED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr );
            }
       });
    }
    if ($('#request-bill').length) {
       $( "#request-bill" ).on( "click", function() {
            if ($('#currentEmployee').length) {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'employee_id': $('#currentEmployee').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_BILLREQUESTED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_BILLREQUESTED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr );
            }
       });
    }
    if ($('#pay-order').length) {
        if( document.getElementById("refreshPaymentLink") ) {
          document.getElementById("refreshPaymentLink").addEventListener("click", async () => {
            const amount = document.getElementById("paymentAmount").value;
            const currency = document.getElementById("paymentCurrency").value;
            const restaurantName = document.getElementById("paymentRestaurantName").value;
            const restaurantId = document.getElementById("paymentRestaurantId").value;
            const openOrderId = document.getElementById("openOrderId").value;
            try {
              const response = await fetch("/payments/create_payment_link", {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json"
                },
                body: JSON.stringify({ openOrderId, amount, currency, restaurantName, restaurantId })
              });
              const data = await response.json();
              if (data.payment_link) {
                $("#paymentlink").text(data.payment_link);
                $("#paymentAnchor").prop("href", data.payment_link);
                fetchQR(data.payment_link)
              } else {
                alert("Failed to generate payment link.");
              }
            } catch (error) {
              console.error("Error:", error);
              alert("Something went wrong.");
            }
          });
        }
        $( "#pay-order" ).on( "click", function() {
            let tip = 0;
            if( $('#tipNumberField').length > 0 ) {
                tip = $('#tipNumberField').val()
            }
            if ($('#currentEmployee').length) {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'employee_id': $('#currentEmployee').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'tip': tip,
                      'menu_id': $('#currentMenu').text(),
                      'status' :  ORDR_CLOSED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr, false );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'tip': tip,
                      'menu_id': $('#currentMenu').text(),
                      'status' :  ORDR_CLOSED
                    }
                };
                const restaurantId = $('#currentRestaurant').text();
                patch( `/restaurants/${restaurantId}/ordrs/`+$('#currentOrder').text(), ordr, false );
            }
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
          updateConnectionStatus('connected', 'Connected');
        },

        disconnected() {
          console.log('Disconnected from OrdrChannel');
          updateConnectionStatus('disconnected', 'Disconnected');
        },

        rejected() {
          console.error('Connection to OrdrChannel was rejected');
          updateConnectionStatus('error', 'Connection rejected');
        },

        received(data) {
          console.log('Received WebSocket message with keys:', Object.keys(data));

          try {
            // Map WebSocket data keys to their corresponding DOM selectors
            const partialsToUpdate = [
              { key: 'context', selector: '#contextContainer' },
              { key: 'modals', selector: '#modalsContainer' },
              {
                key: 'menuContentStaff',
                selector: '#menuContentContainer',
                // For staff content, we need to check if we're in staff mode
                shouldUpdate: () => document.getElementById('menuu') !== null
              },
              {
                key: 'menuContentCustomer',
                selector: '#menuContentContainer',
                // For customer content, we check if we're in customer mode
                shouldUpdate: () => document.getElementById('menuc') !== null
              },
              {
                key: 'orderCustomer',
                selector: '#openOrderContainer',
                shouldUpdate: () => document.getElementById('menuc') !== null
              },
              {
                key: 'orderStaff',
                selector: '#openOrderContainer',
                shouldUpdate: () => document.getElementById('menuu') !== null
              },
              {
                key: 'tableLocaleSelectorStaff',
                selector: '#tableLocaleSelectorContainer',
                shouldUpdate: () => document.getElementById('menuu') !== null
              },
              {
                key: 'tableLocaleSelectorCustomer',
                selector: '#tableLocaleSelectorContainer',
                shouldUpdate: () => document.getElementById('menuc') !== null
              }
            ];

            // Update each partial if it exists in the data and should be updated
            partialsToUpdate.forEach(({ key, selector, shouldUpdate }) => {
              // Skip if the key doesn't exist in the data or shouldn't be updated
              if (!data[key] || (shouldUpdate && !shouldUpdate())) {
                return;
              }

              console.log(`Updating partial: ${key}`);
              const element = document.querySelector(selector);

              if (element) {
                try {
                  const decompressed = decompressPartial(data[key]);

                  // Special handling for menu content to replace the entire container
                  if (key === 'menuContentStaff' || key === 'menuContentCustomer') {
                    element.innerHTML = decompressed;
                  } else {
                    // For other elements, replace the content
                    element.innerHTML = decompressed;
                  }

                  console.log(`Updated ${key} with ${decompressed.length} characters`);
                } catch (error) {
                  console.error(`Error processing ${key}:`, error);
                }
              } else {
                console.warn(`Element not found for selector: ${selector} (key: ${key})`);
              }
            });

            // Handle full page refresh if needed
            if (data.fullPageRefresh && data.fullPageRefresh.refresh === true) {
              console.log('Full page refresh requested');
              window.location.reload();
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
