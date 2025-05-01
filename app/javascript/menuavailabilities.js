document.addEventListener("turbo:load", () => {

    if ($("#menuavailability_dayofweek").is(':visible')) {
      new TomSelect("#menuavailability_dayofweek",{
      });
    }

    if ($("#menuavailability_status").is(':visible')) {
      new TomSelect("#menuavailability_status",{
      });
    }

    if ($("#menuavailability_menu_id").is(':visible')) {
      new TomSelect("#menuavailability_menu_id",{
      });
    }
    if ($("#menuTabs").is(':visible')) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").dayofweek;
            return "<a class='link-dark' href='/menuavailabilities/"+id+"/edit'>"+rowData+"</a>";
        }
        const menuId = document.getElementById('menu-menusection-table').getAttribute('data-bs-menu');
        var menuavailabilityTable = new Tabulator("#menu-menuavailability-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menus/'+menuId+'/menuavailabilities.json',
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
          {title:"Day of Week", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title: 'Available', field: 'starthour', mutator: (value, data) => String(data.starthour).padStart(2, '0') + ':' + String(data.startmin).padStart(2, '0')+' - '+String(data.endhour).padStart(2, '0') + ':' + String(data.endmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title:"Status", field:"status", formatter:status, width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Giorno", //replace the title of column name with the value "Name"
                    "starthour":"Di partenza", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        menuavailabilityTable.on("rowMoved", function(row){
            const rows = menuavailabilityTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'menuavailability': {
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
        menuavailabilityTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("menuavailability-actions").disabled = false;
            } else {
                document.getElementById("menuavailability-actions").disabled = true;
            }
        });
        document.getElementById("activate-menuavailability").addEventListener("click", function(){
            const rows = menuavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menuavailability': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-menuavailability").addEventListener("click", function(){
            const rows = menuavailabilityTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuavailabilityTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menuavailability': {
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