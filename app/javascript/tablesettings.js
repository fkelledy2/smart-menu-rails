document.addEventListener("turbo:load", () => {

    if ($("#tablesetting_tabletype").is(':visible')) {
      new TomSelect("#tablesetting_tabletype",{
      });
    }

    if ($("#tablesetting_status").is(':visible')) {
      new TomSelect("#tablesetting_status",{
      });
    }

    if ($("#tablesetting_restaurant_id").is(':visible')) {
      new TomSelect("#tablesetting_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").is(':visible')) {
        var tableSettingTable = new Tabulator("#restaurant-tablesetting-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/tablesettings.json',
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/tablesettings/",
            }
           },
           {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Type", field:"tabletype", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Capacity", field:"capacity", width: 200, hozAlign:"right", bottomCalc:"sum", headerHozAlign:"right", },
           {title:"Created", field:"created_at", width:200, responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        tableSettingTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-tablesetting").disabled = false;
            document.getElementById("deactivate-tablesetting").disabled = false;
          } else {
            document.getElementById("activate-tablesetting").disabled = true;
            document.getElementById("deactivate-tablesetting").disabled = true;
          }
        });
        document.getElementById("activate-tablesetting").addEventListener("click", function(){
            const rows = tableSettingTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                tableSettingTable.updateData([{id:rows[i].id, status:'free'}]);
                let r = {
                  'tablesetting': {
                      'status': 'free'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-tablesetting").addEventListener("click", function(){
            const rows = tableSettingTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                tableSettingTable.updateData([{id:rows[i].id, status:'archived'}]);
                let r = {
                  'tablesetting': {
                      'status': 'archived'
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