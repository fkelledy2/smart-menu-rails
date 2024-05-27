document.addEventListener("turbo:load", () => {
    if ($("#size-table").is(':visible')) {
        var sizeTable = new Tabulator("#size-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataFill",
          ajaxURL: '/sizes.json',
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Size", field:"id", width:150, responsive:0, formatter:"link", formatterParams: {
                labelField:"size",
                urlPrefix:"/sizes/",
            }
           },
           {title:"Name", field:"name", responsive:0 }
          ],
        });
    }
})