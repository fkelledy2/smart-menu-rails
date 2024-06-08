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
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Description", field:"description", responsive:5},
          {title:"Symbol", field:"symbol", responsive:0, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
        allergynTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("allergyn-actions").disabled = false;
            } else {
                document.getElementById("allergyn-actions").disabled = true;
            }
        });
    }
})