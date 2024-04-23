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

    if ($("#tablesetting-table").is(':visible')) {
        var tableSettingTable = new Tabulator("#tablesetting-table", {
          dataLoader: false,
          maxHeight:"100%",
          minHeight:405,
          paginationSize:20,
          responsiveLayout:true,
          pagination:"local",
          paginationCounter:"rows",
          ajaxURL: '/tablesettings.json',
          layout:"fitColumns",
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
          {
            title:"Restaurant", field:"restaurant.id", responsive:0, width:200, frozen:true, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
          },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/tablesettings/",
            }
           },
           {title:"Type", field:"tabletype", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Capacity", field:"capacity", width: 200, hozAlign:"right", headerHozAlign:"right", },
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
        //trigger an alert message when the row is clicked
        tableSettingTable.on("rowClick", function(e, row){
        });
        tableSettingTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("unarchive-row").disabled = false;
            document.getElementById("archive-row").disabled = false;
          } else {
            document.getElementById("unarchive-row").disabled = true;
            document.getElementById("archive-row").disabled = true;
          }
        });
        document.getElementById("unarchive-row").addEventListener("click", function(){
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
        document.getElementById("archive-row").addEventListener("click", function(){
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