document.addEventListener("turbo:load", () => {

    let locationReload = false;

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
        $("#paymentAmount").val(parseFloat(total).toFixed(2));
    });

    $("#tipNumberField").change(function() {
        $(this).val(parseFloat($(this).val()).toFixed(2));
        let gross = parseFloat($("#orderGross").text());
        let tip = parseFloat($(this).val());
        let total = tip+gross;
        $("#orderGrandTotal").text($('#restaurantCurrency').text()+parseFloat(total).toFixed(2));
    });

    $( "#orderUpdatedButton" ).on( "click", function() {
        if( locationReload ) {
            location.reload();
        }
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
       var locale = $(this).attr('href');
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
        if( document.getElementById("generateLink") ) {
          document.getElementById("generateLink").addEventListener("click", async () => {
            const amount = document.getElementById("paymentAmount").value;
            try {
              const response = await fetch("/create_payment_link", {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json"
                },
                body: JSON.stringify({ amount })
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

    if ($("#restaurantTabs").is(':visible')) {
        function linkOrdr(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").id;
            return "<a class='link-dark' href='/ordrs/"+id+"'>"+rowData+"</a>";
        }
        function linkMenu(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").menu.name;
            return rowData;
        }
        function linkTablesetting(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").tablesetting.name;
            return rowData;
        }
        const restaurantId = document.getElementById('restaurant-ordr-table').getAttribute('data-bs-restaurant_id');
        var restaurantOrdrTable = new Tabulator("#restaurant-ordr-table", {
          pagination:true, //enable.
          paginationSize:5, // this option can take any positive integer value
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/ordrs.json',
          initialSort:[
            {column:"ordrDate", dir:"desc"},
            {column:"id", dir:"desc"},
          ],
          columns: [
           {title:"Id", field:"id", formatter:linkOrdr, frozen:true, responsive:0, hozAlign:"left"},
           {title:"Menu", field:"menu.id", formatter:linkMenu, responsive:0,  hozAlign:"left"},
           {title:"Table", field:"tablesetting.id", formatter:linkTablesetting, responsive:4, hozAlign:"left"},
           {title:"Status", field:"status", responsive:4, hozAlign:"left"},
           {title:"Nett", field:"nett", formatter:"money", hozAlign:"right", responsive:5, headerHozAlign:"right",
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
           },
           {title:"Date", field:"ordrDate", responsive:0, hozAlign:"right", headerHozAlign:"right" },
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"ID",
                    "menu.id":"Menu",
                    "tablesetting.id":"Tavolo",
                    "status":"Stato",
                    "nett":"Tetto",
                    "service":"Servizio",
                    "tax":"Tassare",
                    "gross":"Totale",
                    "ordrDate":"Data",
                }
            },
            "en":{
                "columns":{
                    "id":"ID",
                    "menu.id":"Menu",
                    "tablesetting.id":"Table",
                    "status":"Status",
                    "nett":"nett",
                    "service":"Service",
                    "tax":"Tax",
                    "gross":"Gross",
                    "ordrDate":"Date",
                }
            }
          }
        });
    }

  function fetchQR(paymentUrl) {
    var qrCode = new QRCodeStyling({
           "type":"canvas",
           "shape":"square",
           "width":200,
           "height":200,
           "data": paymentUrl,
           "margin":0,
           "qrOptions":{
              "typeNumber":"0",
              "mode":"Byte",
              "errorCorrectionLevel":"Q"
           },
           "imageOptions":{
              "saveAsBlob":true,
              "hideBackgroundDots":true,
              "imageSize":0.4,
              "margin":0
           },
           "dotsOptions":{
              "type":"extra-rounded",
              "color":"#000000",
              "roundSize":true
           },
           "backgroundOptions":{
              "round":0,
              "color":"#ffffff"
           },
           "image": $("#qrIcon").text(),
           "dotsOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#6a1a4c",
                 "color2":"#6a1a4c",
                 "rotation":"0"
              }
           },
           "cornersSquareOptions":{
              "type":"extra-rounded",
              "color":"#000000"
           },
           "cornersSquareOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "cornersDotOptions":{
              "type":"",
              "color":"#000000"
           },
           "cornersDotOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "backgroundOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#ffffff",
                 "color2":"#ffffff",
                 "rotation":"0"
              }
           }
    });
    document.getElementById('paymentQR').innerHTML = '';
    qrCode.append(document.getElementById('paymentQR'));
  }

})