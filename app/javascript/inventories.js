  document.addEventListener("turbo:load", () => {
    if ($("#inventory-table").is(':visible')) {
        var sizeTable = new Tabulator("#inventory-table", {
          maxHeight:"100%",
          minHeight:405,
          paginationSize:20,
          responsiveLayout:true,
          pagination:"local",
          paginationCounter:"rows",
          ajaxURL: '/inventories.json',
          layout:"fitColumns",
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Inventory Item", field:"id", responsive:0, width:200, frozen:true, formatter:"link", formatterParams: {
                labelField:"menuitem.name",
                urlPrefix:"/inventories/",
            }
           },
           {title:"Starting Inventory", field:"startinginventory", responsive:0, hozAlign:"right", headerHozAlign:"right"},
           {title:"Current Inventory", field:"currentinventory", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Reset Hour", field:"resethour", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", width:200, responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", width:200, responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
    }
})