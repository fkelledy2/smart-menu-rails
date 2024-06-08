document.addEventListener("turbo:load", () => {

    if ($("#menusection_menu_id").is(':visible')) {
      new TomSelect("#menusection_menu_id",{
      });
    }

    if ($("#menusectionConfig").is(':visible')) {
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/menusections/"+id+"/edit'>"+rowData+"</a>";
        }
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
              formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                  cell.getRow().toggleSelect();
              }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Description", field:"description", responsive:5, hozAlign:"left", headerHozAlign:"left" },
          {title:"Status", field:"status", responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
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
            document.getElementById("menusection-actions").disabled = false;
          } else {
            document.getElementById("menusection-actions").disabled = true;
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