document.addEventListener("turbo:load", () => {

    if ($("#tax_taxtype").is(':visible')) {
      new TomSelect("#tax_taxtype",{
      });
    }

    if ($("#tax_restaurant_id").is(':visible')) {
      new TomSelect("#tax_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").is(':visible')) {
        const restaurantId = document.getElementById('restaurant-tax-table').getAttribute('data-bs-restaurant_id');
        var restaurantTaxTable = new Tabulator("#restaurant-tax-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/taxes.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           { rowHandle:true, formatter:"handle", headerSort:false,  frozen:true, width:30, minWidth:30 },
           { title:" ", field:"sequence", formatter:"rownum", width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
           {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/taxes/",
            }
           },
           {title:"Tax Type", field:"taxtype", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Tax Percentage", field:"taxpercentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
                decimal:".",
                symbol:"%",
                symbolAfter:"p",
                precision:2,
            }
           }
          ]
        });
        restaurantTaxTable.on("rowMoved", function(row){
            const rows = restaurantTaxTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantTaxTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'tax': {
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
        restaurantTaxTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-tax").disabled = false;
            document.getElementById("deactivate-tax").disabled = false;
          } else {
            document.getElementById("activate-tax").disabled = true;
            document.getElementById("deactivate-tax").disabled = true;
          }
        });
        document.getElementById("activate-tax").addEventListener("click", function(){
            const rows = restaurantTaxTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTaxTable.updateData([{id:rows[i].id, status:'free'}]);
                let r = {
                  'tax': {
                      'status': 'free'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-tax").addEventListener("click", function(){
            const rows = restaurantTaxTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTaxTable.updateData([{id:rows[i].id, status:'archived'}]);
                let r = {
                  'tax': {
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