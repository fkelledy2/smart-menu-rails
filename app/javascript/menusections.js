document.addEventListener("turbo:load", () => {

    if ($("#menusection_menu_id").is(':visible')) {
      new TomSelect("#menusection_menu_id",{
      });
    }

    if ($("#menusection-table").is(':visible')) {
        var menusectionTable = new Tabulator("#menusection-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          groupBy: ["menu.name"],
          ajaxURL: '/menusections.json',
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
          {
            title:"Menu", field:"menu.id", responsive:0, width:200, formatter:"link", formatterParams: {
                labelField:"menu.name",
                urlPrefix:"/menus/",
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false,  width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menusections/",
            }
           },
           {title:"Status", field:"status", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ]
        });
        menusectionTable.on("rowMoved", function(row){
            const rows = menusectionTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mus = {
                  'menusection': {
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
        //trigger an alert message when the row is clicked
        menusectionTable.on("rowClick", function(e, row){
        });
        menusectionTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = menusectionTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menusection': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = menusectionTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menusection': {
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