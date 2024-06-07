document.addEventListener("turbo:load", () => {
    if ($("#menusectionConfig").is(':visible')) {
        // Allergyns
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/allergyns/"+id+"/edit'>"+rowData+"</a>";
        }
        var allergynTable = new Tabulator("#allergyn-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/allergyns.json',
          columns: [
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Description", field:"description", responsive:5},
          {title:"Symbol", field:"symbol", responsive:0, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
    }
})