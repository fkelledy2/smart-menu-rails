document.addEventListener("turbo:load", () => {

    if ($('#closeOrderModal').length) {
        $('#closeOrderModal').on('hidden.bs.modal', function (e) {
            location.reload();
        });
    }

    if ($('#openOrderModal').length) {
        $('#openOrderModal').on('hidden.bs.modal', function (e) {
            location.reload();
        });
    }
    if ($('#addItemToOrderModal').length) {
        $('#addItemToOrderModal').on('hidden.bs.modal', function (e) {
            location.reload();
        });

        const addItemToOrderModal = document.getElementById('addItemToOrderModal')
        if (addItemToOrderModal) {
          addItemToOrderModal.addEventListener('show.bs.modal', event => {
            // Button that triggered the modal
            const button = event.relatedTarget
            // Extract info from data-bs-* attributes
            const ordr_id = button.getAttribute('data-bs-ordr_id')
            const menuitem_id = button.getAttribute('data-bs-menuitem_id')
            const menuitem_name = button.getAttribute('data-bs-menuitem_name')
            const menuitem_price = button.getAttribute('data-bs-menuitem_price')
            const menuitem_description = button.getAttribute('data-bs-menuitem_description')
            // If necessary, you could initiate an Ajax request here
            // and then do the updating in a callback.

            // Update the modal's content.
            const modalTitle = addItemToOrderModal.querySelector('.modal-title');
            const ordrIdInput = addItemToOrderModal.querySelector('#ordr_id');
            const menuItemIdInput = addItemToOrderModal.querySelector('#menuitem_id');
            const menuItemNameInput = addItemToOrderModal.querySelector('#menuitem_name');
            const menuItemPriceInput = addItemToOrderModal.querySelector('#menuitem_price');
            const menuItemDescriptionInput = addItemToOrderModal.querySelector('#menuitem_description');

            modalTitle.textContent = `Add to Order`;
            ordrIdInput.value = ordr_id;
            menuItemIdInput.value = menuitem_id;
            menuItemNameInput.value = menuitem_name;
            menuItemPriceInput.value = menuitem_price;
            menuItemDescriptionInput.value = menuitem_description;
          })
        }
    }

    if ($('#addItemToOrderButton').length ) {
        document.getElementById("addItemToOrderButton").addEventListener("click", function() {
            let ordrId = $('#ordr_id').val();
            let menuitemId = $('#menuitem_id').val();
            let menuitemPrice = $('#menuitem_price').val();
            let ordritem = {
                'ordritem': {
                    'ordr_id': ordrId,
                    'menuitem_id': menuitemId,
                    'ordritemprice': menuitemPrice
                }
            };
            post( '/ordritems', ordritem );
            return true;
        });
    }
    if ($('#start-order').length) {
        document.getElementById("start-order").addEventListener("click", function() {
            let currentMenu = $('#currentMenu').text();
            let currentRestaurant = $('#currentRestaurant').text();
            let currentTable = $('#currentTable').text();
            let orderStatus = 0;
            if ($('#currentEmployee').length) {
                let currentEmployee = $('#currentEmployee').text();
                let ordr = {
                    'ordr': {
                      'tablesetting_id': currentTable,
                      'employee_id': currentEmployee,
                      'restaurant_id': currentRestaurant,
                      'menu_id': currentMenu,
                      'status' : orderStatus
                    }
                };
                post( '/ordrs', ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': currentTable,
                      'restaurant_id': currentRestaurant,
                      'menu_id': currentMenu,
                      'status' : orderStatus
                    }
                };
                post( '/ordrs', ordr );
            }
            return true;
        });
    }

    if ($('#close-order').length) {
        document.getElementById("close-order").addEventListener("click", function(){
            let currentOrder = $('#currentOrder').text();
            let currentMenu = $('#currentMenu').text();
            let currentRestaurant = $('#currentRestaurant').text();
            let currentTable = $('#currentTable').text();
            let tip = 0;
            if( $('#tip').length > 0 ) {
                tip = $('#tip').val()
            }
            console.log('tip: '+tip);
            let orderStatus = 2;
            if ($('#currentEmployee').length) {
                let currentEmployee = $('#currentEmployee').text();
                let ordr = {
                    'ordr': {
                      'tablesetting_id': currentTable,
                      'employee_id': currentEmployee,
                      'restaurant_id': currentRestaurant,
                      'tip': tip,
                      'menu_id': currentMenu,
                      'status' : orderStatus
                    }
                };
                patch( '/ordrs/'+currentOrder, ordr );
            } else {
                let ordr = {
                    'ordr': {
                      'tablesetting_id': currentTable,
                      'restaurant_id': currentRestaurant,
                      'tip': tip,
                      'menu_id': currentMenu,
                      'status' : orderStatus
                    }
                };
                patch( '/ordrs/'+currentOrder, ordr );
            }
            return true;
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
            });
    }

    if ($("#order-table").length) {
        var orderTable = new Tabulator("#order-table", {
          maxHeight:"100%",
          minHeight:405,
          paginationSize:20,
          groupBy: ["restaurant.name","menu.name", "ordrDate" ],
          responsiveLayout:true,
          pagination:"local",
          paginationCounter:"rows",
          ajaxURL: '/ordrs.json',
          layout:"fitColumns",
          initialSort:[
            {column:"ordrDate", dir:"desc"},
            {column:"id", dir:"desc"},
          ],
          columns: [
           {title:"Date", field:"ordrDate", frozen:true, width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {
            title:"Restaurant", field:"restaurant.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
           },
           {
            title:"Menu", field:"menu.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"menu.name",
                urlPrefix:"/menus/",
            }
           },
           {
            title:"Table", field:"tablesetting.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"tablesetting.name",
                urlPrefix:"/tablesettings/",
            }
           },
           {
            title:"Id", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"id",
                urlPrefix:"/ordrs/",
            }
           },
           {title:"Nett", field:"nett", formatter:"money", hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tip", field:"tip", formatter:"money", hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Service", field:"service", formatter:"money", hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tax", field:"tax", formatter:"money", hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Gross", field:"gross", formatter:"money", hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           }
          ],
        });
        $('#order-table').show();

    }
})