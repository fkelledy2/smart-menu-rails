export function initIngredients() {
    if ($("#ingredient-table").is(':visible')) {
        var sizeTable = new Tabulator("#ingredient-table", {
          dataLoader: false,
          maxHeight:"100%",
          paginationSize:20,
          responsiveLayout:true,
          layout:"fitDataFill",
          ajaxURL: '/ingredients.json',
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Name", field:"id", width:150, responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/ingredients/",
            }
           },
           {title:"Description", field:"description", responsive:0 }
          ]
        });
    }
}
