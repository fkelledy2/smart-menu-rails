document.addEventListener("turbo:load", () => {
    if ($("#restaurantTabs").is(':visible')) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        // Allergyns
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/allergyns/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('allergyn-table').getAttribute('data-bs-restaurant_id');
        var allergynTable = new Tabulator("#allergyn-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          initialSort:[
              {column:"sequence", dir:"asc"},
          ],
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/allergyns.json',
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
           {title:"Symbol", field:"symbol", responsive:1, hozAlign:"right", headerHozAlign:"right" },
           {title:"Description", field:"description", responsive:5},
           {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "symbol":"Simbolo", //replace the title of column name with the value "Name"
                    "description":"Descrizione", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        allergynTable.on("rowMoved", function(row){
            const rows = allergynTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                allergynTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                    'allergyn': {
                        'sequence': rows[i].getPosition(),
                        'restaurant_id': restaurantId
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
        allergynTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("allergyn-actions").disabled = false;
            } else {
                document.getElementById("allergyn-actions").disabled = true;
            }
        });

        document.getElementById("activate-allergyn").addEventListener("click", function(){
            const rows = allergynTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                allergynTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'allergyn': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-allergyn").addEventListener("click", function(){
            const rows = allergynTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                allergynTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'allergyn': {
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