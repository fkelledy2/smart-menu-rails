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

    if ($("#restaurantTabs").is(':visible')) {
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").dayofweek;
            return "<a class='link-dark' href='/restaurantavailabilities/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-openinghour-table').getAttribute('data-bs-restaurant_id');
        var restaurantOpeningHourTable = new Tabulator("#restaurant-openinghour-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/restaurantavailabilities.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", frozen:true, width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", responsive:0, headerSort:false, frozen: true, width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:0, width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Day of Week", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Status", field:"status", responsive:1, hozAlign:"right", headerHozAlign:"right" },
          {title: 'Opening Time', field: 'starthour', mutator: (value, data) => String(data.starthour).padStart(2, '0') + ':' + String(data.startmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title: 'Closing Time', field: 'endhour', mutator: (value, data) => String(data.endhour).padStart(2, '0') + ':' + String(data.endmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" }
          ]
        });
        restaurantOpeningHourTable.on("rowMoved", function(row){
            const rows = restaurantOpeningHourTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
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
        restaurantOpeningHourTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-openinghour").disabled = false;
            document.getElementById("deactivate-openinghour").disabled = false;
          } else {
            document.getElementById("activate-openinghour").disabled = true;
            document.getElementById("deactivate-openinghour").disabled = true;
          }
        });
        document.getElementById("activate-openinghour").addEventListener("click", function(){
            const rows = restaurantOpeningHourTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].id, status:'open'}]);
                let r = {
                  'restaurantavailability': {
                      'status': 'open'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-openinghour").addEventListener("click", function(){
            const rows = restaurantOpeningHourTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].id, status:'closed'}]);
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