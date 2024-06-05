document.addEventListener("turbo:load", () => {

    if ($("#menusection_menu_id").is(':visible')) {
      new TomSelect("#menusection_menu_id",{
      });
    }

    if ($("#menusectionConfig").is(':visible')) {
        const menuId = document.getElementById('menu-menusection-table').getAttribute('data-bs-menu');
        var menusectionTable = new Tabulator("#menu-menusection-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menus/'+menuId+'/menusections.json',
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
          { rowHandle:true, formatter:"handle", headerSort:false,  width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menusections/",
            }
           },
           {title:"Status", field:"status", responsive:0, hozAlign:"right", headerHozAlign:"right" }
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
        menusectionTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-menusection").disabled = false;
            document.getElementById("deactivate-menusection").disabled = false;
          } else {
            document.getElementById("activate-menusection").disabled = true;
            document.getElementById("deactivate-menusection").disabled = true;
          }
        });
        document.getElementById("activate-menusection").addEventListener("click", function(){
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
        document.getElementById("deactivate-menusection").addEventListener("click", function(){
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