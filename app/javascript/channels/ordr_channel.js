import consumer from "./consumer"
import pako from "pako";

function decompressPartial(compressed) {
  if (!compressed || typeof compressed !== 'string') return '';
  const binaryString = atob(compressed);
  const charData = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    charData[i] = binaryString.charCodeAt(i);
  }
  return pako.inflate(charData, { to: 'string' });
}


    let ORDR_OPENED=0;
    let ORDR_ORDERED=20;
    let ORDR_DELIVERED=25;
    let ORDR_BILLREQUESTED=30;
    let ORDR_CLOSED=40;

    let ORDRITEM_ADDED=0;
    let ORDRITEM_REMOVED=10;
    let ORDRITEM_ORDERED=20;
    let ORDRITEM_PREPARED=30;
    let ORDRITEM_DELIVERED=40;

    function closeAllModals() {
      $('.modal').modal('hide'); // Hide all modals
      $('.modal-backdrop').remove(); // Remove backdrop if needed
    }

    function refreshOrderJSLogic() {
        if ($("#smartmenu").is(':visible')) {
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
           patch( '/ordritems/'+ordrItemId, ordritem);
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
                    addItemToOrderModal.querySelector('#a2o_menuitem_image').src = button.getAttribute('data-bs-menuitem_image');
                    addItemToOrderModal.querySelector('#a2o_menuitem_image').alt = button.getAttribute('data-bs-menuitem_name');
                } catch( err ) {
                    // swallow error
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
                post( '/ordritems', ordritem, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
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
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, true );
                } else {
                    let ordr = {
                        'ordr': {
                          'tablesetting_id': $('#currentTable').text(),
                          'restaurant_id': $('#currentRestaurant').text(),
                          'menu_id': $('#currentMenu').text(),
                          'status' : ORDR_ORDERED
                        }
                    };
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, true );
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
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, true );
                } else {
                    let ordr = {
                        'ordr': {
                          'tablesetting_id': $('#currentTable').text(),
                          'restaurant_id': $('#currentRestaurant').text(),
                          'menu_id': $('#currentMenu').text(),
                          'status' : ORDR_BILLREQUESTED
                        }
                    };
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, true );
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
                  const response = await fetch("/create_payment_link", {
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
                          'status' : ORDR_CLOSED
                        }
                    };
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, false );
                } else {
                    let ordr = {
                        'ordr': {
                          'tablesetting_id': $('#currentTable').text(),
                          'restaurant_id': $('#currentRestaurant').text(),
                          'tip': tip,
                          'menu_id': $('#currentMenu').text(),
                          'status' : ORDR_CLOSED
                        }
                    };
                    patch( '/ordrs/'+$('#currentOrder').text(), ordr, false );
                }
            });
        }
    }

    function post( url, body ) {
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
        fetch(url, {
            method: 'PATCH',
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
    function del( url ) {
        fetch(url, {
            method: 'DELETE',
            headers:  {
                  "Content-Type": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            }
        }).then(response => {
        }).catch(function(err) {
            console.info(err + " url: " + url);
        });
    }

var orderId = document.body.dataset.smartmenuId;
if( orderId ) {
    consumer.subscriptions.create({ channel: "OrdrChannel", order_id: orderId }, {
      connected() {
        console.log( 'OrdrChannel:['+orderId+'] - connected');
      },
      disconnected() {
        console.log( 'OrdrChannel:['+orderId+'] - disconnected');
      },
      received(data) {
        console.log('OrdrChannel:['+orderId+'] - message '+data);
        if (data.menuitem_updates) {
          Object.entries(data.menuitem_updates).forEach(([dom_id, html]) => {
            const el = document.getElementById(dom_id);
            if (el) el.outerHTML = html;
          });
          refreshOrderJSLogic();
        } else if( data.fullPageRefresh && data.fullPageRefresh.refresh ) {
          location.reload();
        } else {
          const decompressedPartials = {};
          for (const key in data) {
            if (key === 'fullPageRefresh' || key === 'menuitem_updates') {
              decompressedPartials[key] = data[key];
            } else {
              decompressedPartials[key] = decompressPartial(data[key]);
            }
          }
          // Now use decompressedPartials.context, .modals, etc. as HTML
          if( document.getElementById("currentEmployee") ) {
              document.getElementById("openOrderContainer").innerHTML = decompressedPartials.orderStaff;
              document.getElementById("menuContentContainer").innerHTML = decompressedPartials.menuContentStaff;
              document.getElementById("tableLocaleSelectorContainer").innerHTML = decompressedPartials.tableLocaleSelectorStaff;
          } else {
              document.getElementById("openOrderContainer").innerHTML = decompressedPartials.orderCustomer;
              document.getElementById("menuContentContainer").innerHTML = decompressedPartials.menuContentCustomer;
              document.getElementById("tableLocaleSelectorContainer").innerHTML = decompressedPartials.tableLocaleSelectorCustomer;
          }
          document.getElementById("modalsContainer").innerHTML = decompressedPartials.modals;
          document.getElementById("contextContainer").innerHTML = decompressedPartials.context;
          refreshOrderJSLogic();
        }
        return true;
      }
    });
}

