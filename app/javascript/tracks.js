document.addEventListener("turbo:load", () => {

    if ($("#restaurantTabs").is(':visible')) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").externalid;
            return "<a class='link-dark' href='/tracks/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-tracks-table').getAttribute('data-bs-restaurant_id');
        var restaurantTracksTable = new Tabulator("#restaurant-tracks-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/tracks.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, responsive:0, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", vertAlign:"top", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          { title:"Name", field:"name", responsive:0, hozAlign:"left"},
          { title:"Artist", field:"artist", responsive:3, hozAlign:"left"},
          { title:"Album", field:"description", responsive:4, hozAlign:"left"},
          { title:"Status", field:"status", formatter:status, frozen:true, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "artist":"Artist",
                    "album":"Album",
                    "name":"Nome",
                    "image":"Image",
                    "status":"Stato",
                }
            },
            "en":{
                "columns":{
                    "artist":"Artist",
                    "album":"Album",
                    "name":"Name",
                    "image":"Image",
                    "status":"Status",
                }
            }
          }
        });
        restaurantTracksTable.on("rowMoved", function(row){
            const rows = restaurantTracksTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'track': {
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
        restaurantTracksTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("tracks-actions").disabled = false;
            } else {
                document.getElementById("tracks-actions").disabled = true;
            }
        });
        document.getElementById("activate-track").addEventListener("click", function(){
            const rows = restaurantTracksTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'track': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-track").addEventListener("click", function(){
            const rows = restaurantTracksTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTracksTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'track': {
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