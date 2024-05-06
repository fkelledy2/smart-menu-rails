document.addEventListener("turbo:load", () => {

    if ($("#tax_taxtype").is(':visible')) {
      new TomSelect("#tax_taxtype",{
      });
    }

    if ($("#tax_restaurant_id").is(':visible')) {
      new TomSelect("#tax_restaurant_id",{
      });
    }

    if ($("#tax-table").is(':visible')) {
        var taxTable = new Tabulator("#tax-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/taxes.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
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
           {title:"Tax Type", field:"taxtype", responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Tax Percentage", field:"taxpercentage", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"money", formatterParams:{
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