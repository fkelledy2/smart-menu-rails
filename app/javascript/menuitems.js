document.addEventListener("turbo:load", () => {

    if ($("#menuitem_menusection_id").is(':visible')) {
      new TomSelect("#menuitem_menusection_id",{
      });
    }

    if ($("#menuitem_status").is(':visible')) {
      new TomSelect("#menuitem_status",{
      });
    }

    let restaurantCurrencySymbol = '$';
    if ($('#restaurantCurrency').length) {
        restaurantCurrencySymbol = $('#restaurantCurrency').text();
    }
    if ($("#menuitem-table").is(':visible')) {
        // Menuitems
        var menuItemTable = new Tabulator("#menuitem-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menuitems.json',
          initialSort:[
            {column:"menusection.id", dir:"asc"},
            {column:"sequence", dir:"asc"}
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", frozen:true, width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          {
            title:"Menu Section", field:"menusection.id", responsive:0, formatter:"link", formatterParams: {
                labelField:"menusection.name",
                urlPrefix:"/menusections/",
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false,  width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menuitems/",
            }
           },
           {title:"Status", field:"status", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Calories", field:"calories", hozAlign:"right", headerHozAlign:"right" },
           {title:"Price", field:"price", formatter:"money",  hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           },
          {title:"Prep Time", field:"preptime", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {
               title:"Inventory",
               columns:[
                {title:"Starting", field:"inventory.startinginventory", hozAlign:"right", headerHozAlign:"right" },
                {title:"Current", field:"inventory.currentinventory", hozAlign:"right", headerHozAlign:"right" },
                {title:"Resets At", field:"inventory.resethour", hozAlign:"right", headerHozAlign:"right" },
               ],
           },
           {title:"Created", field:"created_at", responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        menuItemTable.on("rowMoved", function(row){
            const rows = menuItemTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mui = {
                  'menuitem': {
                      'sequence': rows[i].getPosition()
                  }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mui)
                });
            }
        });
        menuItemTable.on("rowClick", function(e, row){
            console.log("Row: " + JSON.stringify(row.getData()));
        });
        menuItemTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = menuItemTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menuitem': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = menuItemTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menuitem': {
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