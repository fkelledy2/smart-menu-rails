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
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
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
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/tablesettings.json',
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, responsive:0, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Type", field:"tabletype", responsive:5, hozAlign:"right", headerHozAlign:"right" },
          {title:"Seats", field:"capacity", responsive:0, hozAlign:"right", bottomCalc:"sum", headerHozAlign:"right" },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "tabletype":"Tipa", //replace the title of column name with the value "Name"
                    "capacity":"Capacità", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            },
            "en":{
                "columns":{
                    "id":"Name", //replace the title of column name with the value "Name"
                    "tabletype":"Type", //replace the title of column name with the value "Name"
                    "capacity":"Capacity", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            }
          }
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
                document.getElementById("tablesetting-actions").disabled = false;
            } else {
                document.getElementById("tablesetting-actions").disabled = true;
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