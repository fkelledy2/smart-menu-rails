document.addEventListener("turbo:load", () => {

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
    });

    $("#tipNumberField").change(function() {
        $(this).val(parseFloat($(this).val()).toFixed(2));
        let gross = parseFloat($("#orderGross").text());
        let tip = parseFloat($(this).val());
        let total = tip+gross;
        $("#orderGrandTotal").text($('#restaurantCurrency').text()+parseFloat(total).toFixed(2));
    });

    $( "#orderUpdatedButton" ).on( "click", function() {
        location.reload();
        return true;
    });

    let restaurantCurrencySymbol = '$';
    if ($('#restaurantCurrency').length) {
        restaurantCurrencySymbol = $('#restaurantCurrency').text();
    }
    if ($('#addNameToParticipantModal').length) {
        const addNameToParticipantModal = document.getElementById('addNameToParticipantModal');
        addNameToParticipantModal.addEventListener('show.bs.modal', event => {
            // Button that triggered the modal
            const button = event.relatedTarget
            // Update the modal's content.
        });
        $( "#addNameToParticipantButton" ).on( "click", function() {
            let ordrparticipant = {
                'ordrparticipant': {
                    'name': addNameToParticipantModal.querySelector('#name').value,
                }
            };
            patch( '/ordrparticipants/'+$('#currentParticipant').text(), ordrparticipant, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            return true;
        });
    }

    $( ".removeItemFromOrderButton" ).on( "click", function(event) {
       var ordrItemId = $(this).attr('data-bs-ordritem_id');
       let ordritem = {
         'ordritem': {
             'status': ORDRITEM_REMOVED,
             'ordritemprice': 0
         }
       };
       patch( '/ordritems/'+ordrItemId, ordritem);
       return true;
    });

    if ($('#addItemToOrderModal').length) {
        const addItemToOrderModal = document.getElementById('addItemToOrderModal');
        addItemToOrderModal.addEventListener('show.bs.modal', event => {
            // Button that triggered the modal
            const button = event.relatedTarget
            // Update the modal's content.
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
            if ($('#currentEmployee').length) {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'employee_id': $('#currentEmployee').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_OPENED
                    }
                };
                post( '/ordrs', ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_OPENED
                    }
                };
                post( '/ordrs', ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_ORDERED
                    }
                };
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_BILLREQUESTED
                    }
                };
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            }
       });
    }

    if ($('#pay-order').length) {
        $( "#pay-order" ).on( "click", function() {
            let tip = 0;
            if( $('#tip').length > 0 ) {
                tip = $('#tip').val()
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, '/menus/'+$('#currentMenu').text()+'/tablesettings/'+$('#currentTable').text() );
            }
        });
    }

    function post( url, body, redirectUrl ) {
        fetch(url, {
            method: 'POST',
            headers:  {
                  "Content-Type": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            },
            body: JSON.stringify(body)
        }).then(response => {
            location.reload();
        }).catch(function(err) {
            console.info(err + " url: " + url);
            location.reload();
        });
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
            location.reload();
        }).catch(function(err) {
            console.info(err + " url: " + url);
            location.reload();
        });
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


    if ($("#order-table").length) {
        var orderTable = new Tabulator("#order-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/ordrs.json',
          initialSort:[
            {column:"ordrDate", dir:"desc"},
            {column:"id", dir:"desc"},
          ],
          columns: [
           {
            title:"Id", field:"id", sorter:"number", responsive:0, formatter:"link", formatterParams: {
                labelField:"id",
                urlPrefix:"/ordrs/",
            }
           },
           {title:"Date", field:"ordrDate", responsive:1, hozAlign:"right", headerHozAlign:"right" },
           {
            title:"Restaurant", field:"restaurant.id", responsive:1, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
           },
           {
            title:"Menu", field:"menu.id", responsive:3, formatter:"link", formatterParams: {
                labelField:"menu.name",
                urlPrefix:"/menus/",
            }
           },
           {
            title:"Table", field:"tablesetting.id", responsive:4, formatter:"link", formatterParams: {
                labelField:"tablesetting.name",
                urlPrefix:"/tablesettings/",
            }
           },
           {title:"Nett", field:"nett", formatter:"money", hozAlign:"right", responsive:0, headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Service", field:"service", formatter:"money", hozAlign:"right", responsive:5, headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tax", field:"tax", formatter:"money", hozAlign:"right", responsive:5, headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Gross", field:"gross", formatter:"money", hozAlign:"right", responsive:0, headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           }
          ],
        });
    }
})