document.addEventListener("turbo:load", () => {
    if ($("#employee-table").is(':visible')) {
        // Employees
        var enployeeTable = new Tabulator("#employee-table", {
          height:405,
          responsiveLayout:true,
          pagination:"local",
          paginationSize:10,
          paginationCounter:"rows",
          ajaxURL: '/employees.json',
          layout:"fitColumns",
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
          {
            title:"Name", field:"id", width: 200, responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/employees/",
            }
           },
           {title: 'EID', field: 'eid', responsive:1},
           {title: 'Email', field: 'user', responsive:1},
           {title:"Role", field:"role", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
           {title:"Status", field:"status", width:150, responsive:0, hozAlign:"right", headerHozAlign:"right" },
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
        //trigger an alert message when the row is clicked
        enployeeTable.on("rowClick", function(e, row){
        });
        enployeeTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = enployeeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                enployeeTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'employee': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = enployeeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                enployeeTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'employee': {
                      'status': 'inactive'
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