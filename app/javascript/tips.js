document.addEventListener("turbo:load", () => {

    if ($("#tip_restaurant_id").is(':visible')) {
      new TomSelect("#tip_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").is(':visible')) {
        var restaurantTipTable = new Tabulator("#restaurant-tip-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/tips.json',
          initialSort:[
            {column:"percentage", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Tip", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"percentage",
                urlPrefix:"/tips/",
            }
          },
          {title:"Tip Percentage", field:"percentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
                decimal:".",
                symbol:"%",
                symbolAfter:"p",
                precision:2,
          }},
          {title:"Created", field:"created_at", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
          }
          ],
        });
        restaurantTipTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-tip").disabled = false;
            document.getElementById("deactivate-tip").disabled = false;
          } else {
            document.getElementById("activate-tip").disabled = true;
            document.getElementById("deactivate-tip").disabled = true;
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