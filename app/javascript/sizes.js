export function initSizes() {
    if ($("#size-table").length) {
        // Sizes
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").size;
            return "<a class='link-dark' href='/sizes/"+id+"/edit'>"+rowData+"</a>";
        }
        const sizeTableElement = document.getElementById('size-table');
        if (!sizeTableElement) return; // Exit if element doesn't exist
        const restaurantId = sizeTableElement.getAttribute('data-bs-restaurant_id');
        var sizeTable = new Tabulator("#size-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          initialSort:[
              {column:"sequence", dir:"asc"},
          ],
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/sizes.json',
          movableRows:true,
          columns: [
           {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, responsive:0, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
            }
           },
           { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
           { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
           {title:"Size", field:"id", responsive:0, formatter:link, hozAlign:"left"},
           {title:"Name", field:"name", responsive:0 },
           {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "en": {
                "columns": {
                    "id": "Size",
                    "name": "Name",
                    "status": "Status"
                }
            },
            "it":{
                "columns":{
                    "id":"Misurare",
                    "name":"Nome",
                    "status":"Stato"
                }
            }
          }
        });
        sizeTable.on("rowMoved", function(row){
            const rows = sizeTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                sizeTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                    'size': {
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
        sizeTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("size-actions").disabled = false;
            } else {
                document.getElementById("size-actions").disabled = true;
            }
        });
        document.getElementById("activate-size").addEventListener("click", function(){
            const rows = sizeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                sizeTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                    'size': {
                        'status': 'active'
                    }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-size").addEventListener("click", function(){
            const rows = sizeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                sizeTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                    'size': {
                        'status': 'inactive'
                    }
                };
                patch( rows[i].url, r );
            }
        });
    }
}