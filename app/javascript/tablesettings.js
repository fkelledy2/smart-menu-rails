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
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/tablesettings/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-tablesetting-table').getAttribute('data-bs-restaurant_id');
        var tableSettingTable = new Tabulator("#restaurant-tablesetting-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/tablesettings.json',
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, responsive:0, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
          {title:"Type", field:"tabletype", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
          {title:"Capacity", field:"capacity", width: 200, hozAlign:"right", bottomCalc:"sum", headerHozAlign:"right", }
          ],
        });
        tableSettingTable.on("rowMoved", function(row){
            const rows = tableSettingTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                tableSettingTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'tablesetting': {
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