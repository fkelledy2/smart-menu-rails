document.addEventListener("turbo:load", () => {
    if ($("#tax-table").is(':visible')) {
        var taxTable = new Tabulator("#tax-table", {
          dataLoader: false,
          height:405,
          responsiveLayout:true,
          pagination:"local",
          paginationSize:10,
          paginationCounter:"rows",
          ajaxURL: '/taxes.json',
          layout:"fitColumns",
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 20, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {
            title:"Restaurant", field:"restaurant_id", responsive:0, width:200, frozen:true, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
           },
           { rowHandle:true, formatter:"handle", headerSort:false,  width:30, minWidth:30 },
           { title:" ", field:"sequence", formatter:"rownum", width: 50, hozAlign:"right", headerHozAlign:"right", headerSort:false },
           {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/taxes/",
            }
           },
           {title:"Tax Type", field:"taxtype", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Tax Percentage", field:"taxpercentage", width: 200, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", width:200, responsive:4, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           },
           {title:"Updated", field:"updated_at", width:200, responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy HH:mm",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        taxTable.on("rowMoved", function(row){
            const rows = taxTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                taxTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'tax': {
                      'sequence': rows[i].getPosition()
                  }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mu)
                });
            }
        });
    }
})