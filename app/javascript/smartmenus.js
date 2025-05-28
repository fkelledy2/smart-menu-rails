document.addEventListener("turbo:load", () => {

    function smlink(cell, formatterParams){
        var id = cell.getValue();
        var name = cell.getRow();
        var rowData = cell.getRow().getData("data").fqlinkname;
        return "<a class='link-dark' href='/smartmenus/"+id+"'>"+rowData+"</a>";
    }

    if ($("#smartmenu-table").is(':visible')) {
        var smartmenuTable = new Tabulator("#smartmenu-table", {
          pagination:"local",
          paginationSize:20,
          movableColumns:true,
          paginationCounter:"rows",
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: "/smartmenus.json",
          ajaxConfig: "GET",
          movableRows:false,
          columns: [
          { title:"", field:"restaurant.country", maxWidth: 125, hozAlign:"right", headerHozAlign:"right", responsive:0, headerFilter:"input", widthGrow: 0 },
          { title:"Address", field:"restaurant.address1", headerFilter:"input", widthGrow: 1 },
          {title:"Menu", field:"slug", responsive:0, formatter:smlink, hozAlign:"left", headerFilter:"input", widthGrow: 3,
            headerFilterFunc: function(headerValue, rowValue, rowData) {
                let filterValue = headerValue.toLowerCase();
                return rowData.restaurant.name.toLowerCase().includes(filterValue) ||
                       rowData.menu.name.toLowerCase().includes(filterValue);
            }
          }
          ]
        });
    }
})