export function initOrdritems() {
    let restaurantCurrencySymbol = '$';
    if ($('#restaurantCurrency').length) {
        restaurantCurrencySymbol = $('#restaurantCurrency').text();
    }
    if ($("#orderitem-table").length) {
        var orderItemTable = new Tabulator("#orderitem-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataFill",
          groupBy:"ordr.id",
          ajaxURL: '/ordritems.json',
          columns: [
           {
            title:"Order", field:"ordr.id", frozen:true, width: 200,  responsive:0, formatter:"link", formatterParams: {
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
           {title:"Price", field:"menuitem.price", formatter:"money", width: 200, hozAlign:"right", headerHozAlign:"right", bottomCalc:"sum", bottomCalcParams:{precision:2},
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:restaurantCurrencySymbol,
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Created", field:"created_at", responsive:4, width: 200, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", responsive:5, width: 200, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
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
}

