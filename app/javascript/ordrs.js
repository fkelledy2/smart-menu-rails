document.addEventListener("turbo:load", () => {

    $('#closeOrderModal').on('hidden.bs.modal', function (e) {
        location.reload();
    });

    $('#openOrderModal').on('hidden.bs.modal', function (e) {
        location.reload();
    });
    if ($('#start-order').length) {
        document.getElementById("start-order").addEventListener("click", function(){
            let currentMenu = $('#currentMenu').text();
            let currentRestaurant = $('#currentRestaurant').text();
            let currentEmployee = $('#currentEmployee').text();
            let currentTable = $('#currentTable').text();
            let ordr = {
                'ordr': {
                  'tablesetting_id': currentTable,
                  'employee_id': currentEmployee,
                  'restaurant_id': currentRestaurant,
                  'menu_id': currentMenu,
                  'status' : 0
                }
            };
            post( '/ordrs', ordr );
            return true;
        });
    }

    if ($('#close-order').length) {
        document.getElementById("close-order").addEventListener("click", function(){
            let currentOrder = $('#currentOrder').text();
            let currentMenu = $('#currentMenu').text();
            let currentRestaurant = $('#currentRestaurant').text();
            let currentEmployee = $('#currentEmployee').text();
            let currentTable = $('#currentTable').text();
            let ordr = {
                'ordr': {
                  'tablesetting_id': currentTable,
                  'employee_id': currentEmployee,
                  'restaurant_id': currentRestaurant,
                  'menu_id': currentMenu,
                  'status' : 2
                }
            };
            patch( '/ordrs/'+currentOrder, ordr );
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
          height:405,
          responsiveLayout:true,
          pagination:"local",
          paginationSize:10,
          paginationCounter:"rows",
          ajaxURL: '/ordrs.json',
          layout:"fitColumns",
          columns: [
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
            title:"Employee", field:"employee.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"employee.name",
                urlPrefix:"/employees/",
            }
           },
           {
            title:"Id", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"id",
                urlPrefix:"/ordrs/",
            }
           },
           {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Nett", field:"nett", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tip", field:"tip", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Service", field:"service", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tax", field:"tax", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Gross", field:"gross", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Created", field:"created_at", responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
    }
})