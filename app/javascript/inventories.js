  document.addEventListener("turbo:load", () => {

    if ($("#inventory_menuitem_id").is(':visible')) {
      new TomSelect("#inventory_menuitem_id",{
      });
    }

    if ($("#inventory-table").is(':visible')) {
        var sizeTable = new Tabulator("#inventory-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/inventories.json',
          columns: [
           {
            title:"Inventory Item", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"menuitem.name",
                urlPrefix:"/inventories/",
            }
           },
           {title:"Starting Inventory", field:"startinginventory", responsive:0, hozAlign:"right", headerHozAlign:"right"},
           {title:"Current Inventory", field:"currentinventory", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Reset Hour", field:"resethour", responsive:3, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
    }
})