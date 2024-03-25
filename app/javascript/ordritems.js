document.addEventListener("turbo:load", () => {

    if ($("#orderitem-table").length) {
        var orderItemTable = new Tabulator("#orderitem-table", {
          height:405,
          responsiveLayout:true,
          pagination:"local",
          paginationSize:10,
          paginationCounter:"rows",
          ajaxURL: '/ordritems.json',
          layout:"fitColumns",
          columns: [
           {
            title:"Order", field:"ordr.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"ordr.id",
                urlPrefix:"/ordrs/",
            }
           },
           {
            title:"Menu Item", field:"menuitem.id", responsive:0, formatter:"link", formatterParams: {
                labelField:"menuitem.name",
                urlPrefix:"/menuitems/",
            }
           },
           {title:"Price", field:"menuitem.price", formatter:"money", width: 100, hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Created", field:"created_at", responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        //trigger an alert message when the row is clicked
        orderItemTable.on("rowClick", function(e, row){
        });
    }
})