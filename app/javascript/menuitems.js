import { initTomSelectIfNeeded } from './tomselect_helper';

export function initMenuitems() {
    if ($("#menuitem_menusection_id").length) {
      initTomSelectIfNeeded("#menuitem_menusection_id",{
      });
    }

    if ($("#menuitem_status").length) {
      initTomSelectIfNeeded("#menuitem_status",{
      });
    }

    if ($("#menuitem_itemtype").length) {
      initTomSelectIfNeeded("#menuitem_itemtype",{
      });
    }
    if ($("#menuitem_sizesupport").length) {
      initTomSelectIfNeeded("#menuitem_sizesupport",{
      });
    }
    let restaurantCurrencySymbol = '$';
    if ($('#restaurantCurrency').length) {
        restaurantCurrencySymbol = $('#restaurantCurrency').text();
    }

    if ($("#sectionTabs").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        // Menuitems
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/menuitems/"+id+"/edit'>"+rowData+"</a>";
        }
        const menuitemTableElement = document.getElementById('menusection-menuitem-table');
        if (!menuitemTableElement) return; // Exit if element doesn't exist
        const menusectionId = menuitemTableElement.getAttribute('data-bs-menusection');
        var menuItemTable = new Tabulator("#menusection-menuitem-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menusections/'+menusectionId+'/menuitems.json',
          initialSort:[
            {column:"sequence", dir:"asc"}
          ],
          movableRows:true,
          columns: [
          {
              formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                  cell.getRow().toggleSelect();
              }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, maxWidth: 180, formatter:link, hozAlign:"left"},
          {title:"genImageId", visible:false, field:"genImageId"},
          {title:"Calories", field:"calories", responsive:5, hozAlign:"right", headerHozAlign:"right" },
          {title:"Price", field:"price", responsive:4, formatter:"money",  hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
          },
          {title:"Prep Time", field:"preptime", responsive:5, hozAlign:"right", headerHozAlign:"right" },
           {
               title:"Inventory",
               columns:[
                {title:"Starting", responsive:5, field:"inventory.startinginventory", hozAlign:"right", headerHozAlign:"right" },
                {title:"Current", responsive:5, field:"inventory.currentinventory", hozAlign:"right", headerHozAlign:"right" },
                {title:"Resets At", responsive:5, field:"inventory.resethour", hozAlign:"right", headerHozAlign:"right" },
               ],
           },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        menuItemTable.on("rowMoved", function(row){
            const rows = menuItemTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mus = {
                    'menuitem': {
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
        menuItemTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("menuitem-actions").disabled = false;
            } else {
                document.getElementById("menuitem-actions").disabled = true;
            }
        });
        document.getElementById("genimage-menuitem").addEventListener("click", function(){
            const rows = menuItemTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                let r = {
                    'genimage': {
                        'id': rows[i].genImageId
                    }
                };
                patch( '/genimages/'+rows[i].genImageId, r );
            }
        });
        document.getElementById("activate-menuitem").addEventListener("click", function(){
            const rows = menuItemTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                    'menuitem': {
                        'status': 'active'
                    }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-menuitem").addEventListener("click", function(){
            const rows = menuItemTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuItemTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                    'menuitem': {
                        'status': 'inactive'
                    }
                };
                patch( rows[i].url, r );
            }
        });
    }
}
