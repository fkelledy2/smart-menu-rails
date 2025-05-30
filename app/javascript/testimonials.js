document.addEventListener("turbo:load", () => {

    if ($("#testimonial-table").is(':visible')) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        var testimonialTable = new Tabulator("#testimonial-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          ajaxURL: '/testimonials.json',
          movableRows:true,
          columns: [
          {
              formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                  cell.getRow().toggleSelect();
              }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          {title:"", field:"sequence", visible:true, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Testimonial", field:"testimonial", responsive:0, hozAlign:"left"},
          {title:"Author", field:"user.first_name", responsive:0, hozAlign:"left"},
          {title:"Restaurant", field:"restaurant.name", responsive:0, hozAlign:"left"},
          {title:"Status", field:"status", formatter:status, responsive:0, hozAlign:"right", headerHozAlign:"right" }
          ]
        });
        testimonialTable.on("rowMoved", function(row){
            const rows = testimonialTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                testimonialTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                    'testimonial': {
                        'sequence': rows[i].getPosition()-1
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
        testimonialTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("testimonial-actions").disabled = false;
            } else {
                document.getElementById("testimonial-actions").disabled = true;
            }
        });
        document.getElementById("approve-testimonial").addEventListener("click", function(){
            const rows = testimonialTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                testimonialTable.updateData([{id:rows[i].id, status:'approved'}]);
                let r = {
                  'testimonial': {
                      'status': 'approved'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("unapprove-testimonial").addEventListener("click", function(){
            const rows = testimonialTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                testimonialTable.updateData([{id:rows[i].id, status:'unapproved'}]);
                let r = {
                  'testimonial': {
                      'status': 'unapproved'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        function patch( url, body ) {
                fetch(url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(body)
                });
        }
    }
})