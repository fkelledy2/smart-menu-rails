document.addEventListener("turbo:load", () => {
    if ($("#restaurant-table").is(':visible')) {
        // Restaurants
        var restaurantTable = new Tabulator("#restaurant-table", {
          dataLoader: false,
          maxHeight:"100%",
          minHeight:405,
          paginationSize:20,
          responsiveLayout:true,
          pagination:"local",
          paginationCounter:"rows",
          ajaxURL: '/restaurants.json',
          layout:"fitColumns",
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Name", field:"id", width: 200, responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/restaurants/",
            }
           },
           {
              title: 'Address',
              field: 'address', responsive:1,
              mutator: (value, data) => data.address1 + '\n' + data.address2 + '\n' + data.state + '\n' + data.city + '\n' + data.postcode,
           },
           {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Capacity", field:"total_capacity", hozAlign:"right", headerHozAlign:"right", width:150, responsive:3},
           {title:"Created", field:"created_at", width:200, responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", width:200, responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
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