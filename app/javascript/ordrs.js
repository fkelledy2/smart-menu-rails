document.addEventListener("turbo:load", () => {
    if ($("#order-table").is(':visible')) {
        var orderTable = new Tabulator("#order-table", {
          height:405,
          responsiveLayout:true,
          pagination:"local",
          paginationSize:10,
          paginationCounter:"rows",
          ajaxURL: '/ordrs.json',
          layout:"fitColumns",
          columns: [
           {
            title:"Restaurant", field:"restaurant.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
           },
           {
            title:"Menu", field:"menu.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"menu.name",
                urlPrefix:"/menus/",
            }
           },
           {
            title:"Table", field:"tablesetting.id", frozen:true, responsive:0, formatter:"link", formatterParams: {
                labelField:"tablesetting.name",
                urlPrefix:"/tablesettings/",
            }
           },
           {
            title:"Id", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"id",
                urlPrefix:"/ordrs/",
            }
           },
           {title:"Nett", field:"nett", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tip", field:"tip", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Service", field:"service", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Tax", field:"tax", formatter:"money", hozAlign:"right", headerHozAlign:"right",
            formatterParams:{
               decimal:".",
               thousand:",",
               symbol:"$",
               negativeSign:true,
               precision:2,
            }
           },
           {title:"Gross", field:"gross", formatter:"money", hozAlign:"right", headerHozAlign:"right",
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
    }
})