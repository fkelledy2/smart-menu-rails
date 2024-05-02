document.addEventListener("turbo:load", () => {

    if ($("#menuavailability_dayofweek").is(':visible')) {
      new TomSelect("#menuavailability_dayofweek",{
      });
    }

    if ($("#menuavailability_status").is(':visible')) {
      new TomSelect("#menuavailability_status",{
      });
    }

    if ($("#menuavailability_menu_id").is(':visible')) {
      new TomSelect("#menuavailability_menu_id",{
      });
    }

    if ($("#menuavailability-table").is(':visible')) {
        var menuavailabilityTable = new Tabulator("#menuavailability-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataFill",
          groupBy: ["menu.id"],
          ajaxURL: '/menuavailabilities.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", frozen:true, width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          {
            title:"Menu", field:"menu.id", responsive:0, width:200, frozen:true, formatter:"link", formatterParams: {
                labelField:"menu.name",
                urlPrefix:"/menus/",
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false,  width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Day of Week", field:"id", responsive:0, width:200, formatter:"link", formatterParams: {
                labelField:"dayofweek",
                urlPrefix:"/menuavailabilities/",
            }
          },
          {title: 'Opening Time', field: 'starthour', mutator: (value, data) => String(data.starthour).padStart(2, '0') + ':' + String(data.startmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title: 'Closing Time', field: 'endhour', mutator: (value, data) => String(data.endhour).padStart(2, '0') + ':' + String(data.endmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },

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
          ]
        });
        menuavailabilityTable.on("rowMoved", function(row){
            const rows = menuavailabilityTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'menuavailability': {
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
        menuavailabilityTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = menuavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].id, status:'open'}]);
                let r = {
                  'menuavailability': {
                      'status': 'open'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = menuavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].id, status:'closed'}]);
                let r = {
                  'menuavailability': {
                      'status': 'closed'
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