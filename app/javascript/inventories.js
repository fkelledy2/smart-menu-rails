  document.addEventListener("turbo:load", () => {

    if ($("#inventory_menuitem_id").is(':visible')) {
      new TomSelect("#inventory_menuitem_id",{
      });
    }

    if ($("#sectionTabs").is(':visible')) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        // Menuitems
        function link(cell, formatterParams){
           var id = cell.getValue();
           var name = cell.getRow();
           var rowData = cell.getRow().getData("data").menuitem.name;
           return "<a class='link-dark' href='/inventories/"+id+"/edit'>"+rowData+"</a>";
        }
        var inventoryTable = new Tabulator("#menusection-inventory-table", {
            dataLoader: false,
            maxHeight:"100%",
            responsiveLayout:true,
            layout:"fitDataStretch",
            ajaxURL: '/inventories.json',
            initialSort:[
                {column:"sequence", dir:"asc"}
            ],
            movableRows:true,
            columns: [
            {
                formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                    cell.getRow().toggleSelect();
                }
            },
            { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
            { title:"", field:"sequence", visible:true, formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
            {title:"Item", field:"id", responsive:0, maxWidth: 180, formatter:link, hozAlign:"left"},
            {title:"Inventory", field: "inventory", responsive:0, hozAlign:"right", headerHozAlign:"right", mutator: (value, data) => data.currentinventory + '/' + data.startinginventory },
            {title:"Resets At", field:"resethour", responsive:3, hozAlign:"right", headerHozAlign:"right" },
            {title:"Status", field:"status", formatter:status, responsive:3, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Articolo", //replace the title of column name with the value "Name"
                    "inventory":"inventario", //replace the title of column name with the value "Name"
                    "resethour":"Si ripristina a", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        inventoryTable.on("rowMoved", function(row){
            const rows = inventoryTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                inventoryTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mus = {
                    'inventory': {
                        'sequence': rows[i].getPosition()
                    }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                        "Content-Type": "application/json",
                        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mus)
                });
            }
        });
        inventoryTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("inventory-actions").disabled = false;
            } else {
                document.getElementById("inventory-actions").disabled = true;
            }
        });
        document.getElementById("activate-inventory").addEventListener("click", function(){
            const rows = inventoryTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                inventoryTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                    'inventory': {
                        'status': 'active'
                    }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-inventory").addEventListener("click", function(){
            const rows = inventoryTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                inventoryTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                    'inventory': {
                        'status': 'inactive'
                    }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("reset-inventory").addEventListener("click", function(){
            const rows = inventoryTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                inventoryTable.updateData([{id:rows[i].id, currentinventory: rows[i].startinginventory}]);
                let r = {
                    'inventory': {
                        'currentinventory': rows[i].startinginventory
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