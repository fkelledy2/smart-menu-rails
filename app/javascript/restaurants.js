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
             formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
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
})