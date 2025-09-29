import { initTomSelectIfNeeded } from './tomselect_helper';

export function initRestaurantavailabilities() {
    if ($("#restaurantavailability_dayofweek").length) {
      initTomSelectIfNeeded("#restaurantavailability_dayofweek",{
      });
    }

    if ($("#restaurantavailability_status").length) {
      initTomSelectIfNeeded("#restaurantavailability_status",{
      });
    }

    if ($("#restaurantavailability_restaurant_id").length) {
      initTomSelectIfNeeded("#restaurantavailability_restaurant_id",{
      });
    }

    if ($("#restaurantTabs").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").dayofweek;
            return "<a class='link-dark' href='/restaurantavailabilities/"+id+"/edit'>"+rowData+"</a>";
        }
        const openingHourTableElement = document.getElementById('restaurant-openinghour-table');
        if (!openingHourTableElement) return; // Exit if element doesn't exist
        const restaurantId = openingHourTableElement.getAttribute('data-bs-restaurant_id');
        var restaurantOpeningHourTable = new Tabulator("#restaurant-openinghour-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/restaurantavailabilities.json',
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
          { rowHandle:true, formatter:"handle", responsive:0, headerSort:false, frozen: true, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:0, width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Day of Week", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title: 'Openings', field: 'starthour', mutator: (value, data) => String(data.starthour).padStart(2, '0') + ':' + String(data.startmin).padStart(2, '0')+' - '+String(data.endhour).padStart(2, '0') + ':' + String(data.endmin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Giorno", //replace the title of column name with the value "Name"
                    "starthour":"Di partenza", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            },
            "en":{
                "columns":{
                    "id":"Day", //replace the title of column name with the value "Name"
                    "starthour":"Openings", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        restaurantOpeningHourTable.on("rowMoved", function(row){
            const rows = restaurantOpeningHourTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'restaurantavailability': {
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
        restaurantOpeningHourTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("openinghour-actions").disabled = false;
            } else {
                document.getElementById("openinghour-actions").disabled = true;
            }
        });
        document.getElementById("activate-openinghour").addEventListener("click", function(){
            const rows = restaurantOpeningHourTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].id, status:'open'}]);
                let r = {
                  'restaurantavailability': {
                      'status': 'open'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-openinghour").addEventListener("click", function(){
            const rows = restaurantOpeningHourTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantOpeningHourTable.updateData([{id:rows[i].id, status:'closed'}]);
                let r = {
                  'restaurantavailability': {
                      'status': 'closed'
                  }
                };
                patch( rows[i].url, r );
            }
        });
    }
}

