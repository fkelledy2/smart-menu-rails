import consumer from "./consumer"

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

consumer.subscriptions.create("OrdrChannel", {
  connected() {
    console.log( 'connected');
  },

  disconnected() {
    console.log( 'disconnected');
  },

  received(data) {
    console.log( 'received:'+JSON.stringify(data));
//        location.reload();
    if( document.getElementById("currentEmployee") ) {
        document.getElementById("openOrderContainer").innerHTML = data.orderStaff;
    } else {
        document.getElementById("openOrderContainer").innerHTML = data.orderCustomer;
    }
    document.getElementById("viewOrderModalContainer").innerHTML = data.viewOrderModal;
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
    return true;
  }
});
