document.addEventListener("turbo:load", () => {
    if ($("#size-table").is(':visible')) {
        // Sizes
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").size;
            return "<a class='link-dark' href='/sizes/"+id+"/edit'>"+rowData+"</a>";
        }
        var sizeTable = new Tabulator("#size-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          initialSort:[
              {column:"sequence", dir:"asc"},
          ],
          layout:"fitDataStretch",
          ajaxURL: '/sizes.json',
          movableRows:true,
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {title:"Size", field:"id", responsive:0, formatter:link, hozAlign:"left"},
           {title:"Name", field:"name", responsive:0 },
           {title:"Status", field:"status", responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
        sizeTable.on("rowMoved", function(row){
            const rows = sizeTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                allergynTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                    'size': {
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