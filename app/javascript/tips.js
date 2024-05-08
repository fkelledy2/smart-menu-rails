document.addEventListener("turbo:load", () => {

    if ($("#tip_restaurant_id").is(':visible')) {
      new TomSelect("#tip_restaurant_id",{
      });
    }

    if ($("#tip-table").is(':visible')) {
        var taxTable = new Tabulator("#tip-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/tips.json',
          initialSort:[
            {column:"percentage", dir:"asc"},
          ],
          columns: [
           {
            title:"Tip", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"percentage",
                urlPrefix:"/tips/",
            }
           },
           {title:"Tip Percentage", field:"percentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
                decimal:".",
                symbol:"%",
                symbolAfter:"p",
                precision:2,
           }},
           {title:"Created", field:"created_at", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
    }
})