
export function initOrders() {

    // Define utility functions first
    function post( url, body ) {
      $('#orderCart').hide();
      $('#orderCartSpinner').show();

        fetch(url, {
            method: 'POST',
            headers:  {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            },
            body: JSON.stringify(body)
        }).then(response => {
            if (response.ok) {
                return response.json();
            }
            throw new Error('Network response was not ok.');
        }).then(data => {
            console.log('Success:', data);
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
            // Handle success response
        }).catch(error => {
            console.error('Error:', error);
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
            // Handle error
        });
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
            if (response.ok) {
                return response.json();
            }
            throw new Error('Network response was not ok.');
        }).then(data => {
            console.log('PATCH Success:', data);
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
        }).catch(error => {
            console.error('PATCH Error:', error);
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
        });
    }

    function del( url ) {
      $('#orderCart').hide();
      $('#orderCartSpinner').show();
        fetch(url, {
            method: 'DELETE',
            headers:  {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
            }
        }).then(response => {
            if (response.ok) {
                console.log('DELETE Success');
            } else {
                throw new Error('Network response was not ok.');
            }
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
        }).catch(error => {
            console.error('DELETE Error:', error);
            $('#orderCartSpinner').hide();
            $('#orderCart').show();
        });
    }

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

    let restaurantCurrencySymbol = '$';

    if( document.getElementById("openOrderModalLabel") ) {
        document.getElementById("openOrderModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("openOrderModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("addItemToOrderModalLabel") ) {
        document.getElementById("addItemToOrderModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("addItemToOrderModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("filterOrderModalLabel") ) {
        document.getElementById("filterOrderModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("filterOrderModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("viewOrderModalLabel") ) {
        document.getElementById("viewOrderModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("viewOrderModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("requestBillModalLabel") ) {
        document.getElementById("requestBillModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("requestBillModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("payOrderModalLabel") ) {
        document.getElementById("payOrderModalLabel").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("payOrderModalLabel").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
    }
    if( document.getElementById("addNameToParticipantModal") ) {
        document.getElementById("addNameToParticipantModal").addEventListener("shown.bs.modal", () => {
          document.getElementById("backgroundContent").setAttribute("inert", "");
        });
        document.getElementById("addNameToParticipantModal").addEventListener("hidden.bs.modal", () => {
          document.getElementById("backgroundContent").removeAttribute("inert");
        });
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
                const imageElement = addItemToOrderModal.querySelector('#a2o_menuitem_image');
                if (imageElement) {
                    imageElement.src = button.getAttribute('data-bs-menuitem_image');
                    imageElement.alt = button.getAttribute('data-bs-menuitem_name');
                }
            } catch( err ) {
                console.log(err);
            }
        });
        $( "#addItemToOrderButton" ).on( "click", function() {
            // Debug: Check if required elements exist
            const ordrId = $('#a2o_ordr_id').text();
            const menuitemId = $('#a2o_menuitem_id').text();
            const price = $('#a2o_menuitem_price').text();
            const restaurantId = $('#currentRestaurant').text();
            
            console.log('Order Item Debug:', {
                ordrId: ordrId,
                menuitemId: menuitemId,
                price: price,
                restaurantId: restaurantId,
                status: ORDRITEM_ADDED
            });
            
            // Check for missing required data
            if (!ordrId || !menuitemId || !restaurantId) {
                console.error('Missing required data for order item creation');
                return false;
            }
            
            let ordritem = {
                'ordritem': {
                    'ordr_id': ordrId,
                    'menuitem_id': menuitemId,
                    'status': ORDRITEM_ADDED,
                    'ordritemprice': price
                }
            };
            
            console.log('Sending order item:', ordritem);
            post( `/restaurants/${restaurantId}/ordritems`, ordritem );
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
                const restaurantId = $('#currentRestaurant').text();
                post( `/restaurants/${restaurantId}/ordrs`, ordr );
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
                const restaurantId = $('#currentRestaurant').text();
                post( `/restaurants/${restaurantId}/ordrs`, ordr );
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_ORDERED
                    }
                };
                patch( '/ordrs/'+$('#currentOrder').text(), ordr );
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
                patch( '/ordrs/'+$('#currentOrder').text(), ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': $('#currentTable').text(),
                      'restaurant_id': $('#currentRestaurant').text(),
                      'menu_id': $('#currentMenu').text(),
                      'status' : ORDR_BILLREQUESTED
                    }
                };
                patch( '/ordrs/'+$('#currentOrder').text(), ordr );
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
                      'status' :  ORDR_CLOSED
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
                      'status' :  ORDR_CLOSED
                    }
                };
                patch( '/ordrs/'+$('#currentOrder').text(), ordr, false );
            }
        });
    }
}


    refreshOrderJSLogic();

    if ($("#restaurantTabs").length) {
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
        const ordrTableElement = document.getElementById('restaurant-ordr-table');
        if (!ordrTableElement) return; // Exit if element doesn't exist
        const restaurantId = ordrTableElement.getAttribute('data-bs-restaurant_id');
        var restaurantOrdrTable = new Tabulator("#restaurant-ordr-table", {
          pagination:true, //enable.
          paginationSize:10, // this option can take any positive integer value
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitColumns",
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



  const tableElement = document.getElementById('dw-orders-mv-table');
  const loadingElement = document.getElementById('tabulator-loading');
  if (!tableElement || !loadingElement) return;

  showLoading();
  fetchData()
    .then(data => {
      hideLoading();
      if (!data || data.length === 0) {
        tableElement.innerHTML = '<div class="alert alert-info">No data found.</div>';
        return;
      }
      renderTable(tableElement, data);
    })
    .catch(error => {
      hideLoading();
      tableElement.innerHTML = '<div class="alert alert-danger">Failed to load data.</div>';
    });

  function showLoading() {
    loadingElement.style.display = 'block';
  }

  function hideLoading() {
    loadingElement.style.display = 'none';
  }

  function fetchData() {
    const url = tableElement.getAttribute('data-json-url');
    return fetch(url).then(response => response.json());
  }

  function renderTable(element, data) {
    const columns = Object.keys(data[0]).map(key => ({
      title: key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
      field: key,
      headerFilter: true
    }));
    columns.push({
      title: "Actions",
      formatter: function(cell, formatterParams, onRendered) {
        const id = cell.getRow().getData().id;
        return id ? `<a href='/dw_orders_mv/${id}'>Show</a>` : '';
      }
    });
    new Tabulator(element, {
      data: data,
      layout: "fitDataTable",
      columns: columns,
      movableColumns: true
    });
  }
}