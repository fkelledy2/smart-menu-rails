document.addEventListener("turbo:load", () => {

    if ($("#restaurant_status").is(':visible')) {
      new TomSelect("#restaurant_status",{
      });
    }

    if ($("#restaurant_displayImages").is(':visible')) {
      new TomSelect("#restaurant_displayImages",{
      });
    }

    if ($("#restaurant_allowOrdering").is(':visible')) {
      new TomSelect("#restaurant_allowOrdering",{
      });
    }

    if ($("#restaurant_inventoryTracking").is(':visible')) {
      new TomSelect("#restaurant_inventoryTracking",{
      });
    }

    if ($("#restaurant_country").is(':visible')) {
      new TomSelect("#restaurant_country",{
      });
    }

    if ($("#restaurant-table").is(':visible')) {
        // Restaurants
        var restaurantTable = new Tabulator("#restaurant-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants.json',
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/restaurants/",
            }
           },
           {title:"Status", field:"status", responsive:3, hozAlign:"right", headerHozAlign:"right" },
           {title:"Capacity", field:"total_capacity", responsive:2, hozAlign:"right", headerHozAlign:"right"},
           {
              title: 'Address',
              field: 'address', responsive:4,
              mutator: (value, data) => data.address1 + '\n' + data.address2 + '\n' + data.state + '\n' + data.city + '\n' + data.postcode,
           },
           {title:"Created", field:"created_at", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });

        restaurantTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("restaurant-activate-row").disabled = false;
            document.getElementById("restaurant-deactivate-row").disabled = false;
          } else {
            document.getElementById("restaurant-activate-row").disabled = true;
            document.getElementById("restaurant-deactivate-row").disabled = true;
          }
        });

        document.getElementById("restaurant-activate-row").addEventListener("click", function(){
            const rows = restaurantTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'restaurant': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });

        document.getElementById("restaurant-deactivate-row").addEventListener("click", function(){
            const rows = restaurantTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'restaurant': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
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
    }

    if ($("#restaurantTabs").is(':visible')) {
        var restaurantMenuTable = new Tabulator("#restaurant-menu-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menus.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, responsive:0, width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menus/",
            }
           },
           {title:"Status", field:"status", responsive:4, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        restaurantMenuTable.on("rowMoved", function(row){
            const rows = restaurantMenuTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'menu': {
                      'sequence': rows[i].getPosition()
                  }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mu)
                });
            }
        });
        restaurantMenuTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = restaurantMenuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantMenuTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menu': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = restaurantMenuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantMenuTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menu': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
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
    }




})