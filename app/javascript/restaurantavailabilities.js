document.addEventListener("turbo:load", () => {

    if ($("#restaurantavailability_dayofweek").is(':visible')) {
      new TomSelect("#restaurantavailability_dayofweek",{
      });
    }

    if ($("#restaurantavailability_status").is(':visible')) {
      new TomSelect("#restaurantavailability_status",{
      });
    }

    if ($("#restaurantavailability_restaurant_id").is(':visible')) {
      new TomSelect("#restaurantavailability_restaurant_id",{
      });
    }

    if ($("#restaurantavailability-table").is(':visible')) {
        var restaurantavailabilityTable = new Tabulator("#restaurantavailability-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurantavailabilities.json',
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
          { rowHandle:true, formatter:"handle", responsive:0, headerSort:false,  width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:0, width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Day of Week", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"dayofweek",
                urlPrefix:"/restaurantavailabilities/",
            }
          },
          {title:"Status", field:"status", responsive:1, hozAlign:"right", headerHozAlign:"right" },
          {title: 'Opening Time', field: 'starthour', mutator: (value, data) => String(data.starthour).padStart(2, '0') + ':' + String(data.startmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title: 'Closing Time', field: 'endhour', mutator: (value, data) => String(data.endhour).padStart(2, '0') + ':' + String(data.endmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title:"Created", field:"created_at", responsive:3, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
          }
          ]
        });
        restaurantavailabilityTable.on("rowMoved", function(row){
            const rows = restaurantavailabilityTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantavailabilityTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'restaurantavailability': {
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
        restaurantavailabilityTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = restaurantavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantavailabilityTable.updateData([{id:rows[i].id, status:'open'}]);
                let r = {
                  'restaurantavailability': {
                      'status': 'open'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = restaurantavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantavailabilityTable.updateData([{id:rows[i].id, status:'closed'}]);
                let r = {
                  'restaurantavailability': {
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