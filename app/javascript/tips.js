document.addEventListener("turbo:load", () => {

    if ($("#tip_restaurant_id").is(':visible')) {
      new TomSelect("#tip_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").is(':visible')) {
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").percentage;
            return "<a class='link-dark' href='/tips/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-tip-table').getAttribute('data-bs-restaurant_id');
        var restaurantTipTable = new Tabulator("#restaurant-tip-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/tips.json',
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
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          { title:"Tip", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          { title:"%", field:"percentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
                decimal:".",
                symbol:"",
                symbolAfter:"p",
                precision:2,
           }
          },
          {title:"Status", field:"status", responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ]
        });
        restaurantTipTable.on("rowMoved", function(row){
            const rows = restaurantTipTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantTipTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'tip': {
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
        restaurantTipTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("tip-actions").disabled = false;
            } else {
                document.getElementById("tip-actions").disabled = true;
            }
        });
        document.getElementById("activate-tip").addEventListener("click", function(){
            const rows = restaurantTipTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTipTable.updateData([{id:rows[i].id, status:'free'}]);
                let r = {
                  'tip': {
                      'status': 'free'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-tablesetting").addEventListener("click", function(){
            const rows = restaurantTipTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTipTable.updateData([{id:rows[i].id, status:'archived'}]);
                let r = {
                  'tip': {
                      'status': 'archived'
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