import { initTomSelectIfNeeded } from './tomselect_helper';

export function initRestaurantlocales() {
    if ($("#restaurantlocale_restaurant_id").length) {
      initTomSelectIfNeeded("#restaurantlocale_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function dfault(cell, formatterParams){
            if( cell.getRow().getData("data").dfault ) {
                return 'TRUE'
            } else {
                return 'FALSE'
            }
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").locale;
            return "<a class='link-dark' href='/restaurantlocales/"+id+"/edit'>"+rowData+"</a>";
        }
        const localeTableElement = document.getElementById('restaurant-locale-table');
        if (!localeTableElement) return; // Exit if element doesn't exist
        const restaurantId = localeTableElement.getAttribute('data-bs-restaurant_id');
        var restaurantLocaleTable = new Tabulator("#restaurant-locale-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/restaurantlocales.json',
          initialSort:[
            {column:"locale", dir:"asc"},
          ],
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"Locale", field:"locale", responsive:0, hozAlign:"left"},
          { title:"Default", field:"dfault", formatter:dfault, responsive:0, hozAlign:"left"},
          { title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "Locale":"Locale", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            },
            "en":{
                "columns":{
                    "Locale":"Locale", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        restaurantLocaleTable.on("rowMoved", function(row){
            const rows = restaurantLocaleTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantLocaleTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'restaurantlocale': {
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
        restaurantLocaleTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("locale-actions").disabled = false;
            } else {
                document.getElementById("locale-actions").disabled = true;
            }
        });
        document.getElementById("activate-locale").addEventListener("click", function(){
            const rows = restaurantLocaleTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantLocaleTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'restaurantlocale': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-locale").addEventListener("click", function(){
            const rows = restaurantLocaleTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantLocaleTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'restaurantlocale': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("default-locale").addEventListener("click", function(){
            const rows = restaurantLocaleTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantLocaleTable.updateData([{id:rows[i].id, dfault:true}]);
                let r = {
                  'restaurantlocale': {
                      'dfault': 'true'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("delete-locale").addEventListener("click", function(){
            const rows = restaurantLocaleTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                del( rows[i].url.replace('.json', '') );
            }
        });
    }
}

