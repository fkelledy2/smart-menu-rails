import { initTomSelectIfNeeded } from './tomselect_helper';
export function initTaxes() {
    if ($("#tax_taxtype").length) {
      initTomSelectIfNeeded("#tax_taxtype",{
      });
    }

    if ($("#tax_restaurant_id").length) {
      initTomSelectIfNeeded("#tax_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/taxes/"+id+"/edit'>"+rowData+"</a>";
        }
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
               formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, responsive:0, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                   cell.getRow().toggleSelect();
               }
           },
           { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
           { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
           { title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
           { title:"Type", field:"taxtype", responsive:5, hozAlign:"right", headerHozAlign:"right" },
           { title:"%", field:"taxpercentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
                decimal:".",
                symbol:"",
                symbolAfter:"p",
                precision:2,
            }
           },
           { title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "taxtype":"Typa", //replace the title of column name with the value "Name"
                    "taxpercentage":"%", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            },
            "en":{
                "columns":{
                    "id":"Name", //replace the title of column name with the value "Name"
                    "taxtype":"Type", //replace the title of column name with the value "Name"
                    "taxpercentage":"%", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            }
          }
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
                document.getElementById("tax-actions").disabled = false;
            } else {
                document.getElementById("tax-actions").disabled = true;
            }
        });
        document.getElementById("activate-tax").addEventListener("click", function(){
            const rows = restaurantTaxTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTaxTable.updateData([{id:rows[i].id, status:'free'}]);
                let r = {
                  'tax': {
                      'status': 'active'
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
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
    }
}
