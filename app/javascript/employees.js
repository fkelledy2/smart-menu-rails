document.addEventListener("turbo:load", () => {

    if ($("#employee_status").is(':visible')) {
      new TomSelect("#employee_status",{
      });
    }

    if ($("#employee_role").is(':visible')) {
      new TomSelect("#employee_role",{
      });
    }

    if ($("#employee_restaurant_id").is(':visible')) {
      new TomSelect("#employee_restaurant_id",{
      });
    }

    if ($("#employee_user_id").is(':visible')) {
      new TomSelect("#employee_user_id",{
      });
    }

    if ($("#employee-table").is(':visible')) {
        // Employees
        var enployeeTable = new Tabulator("#employee-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/employees.json',
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/employees/",
            }
           },
           {title:"Status", field:"status", responsive:1, hozAlign:"right", headerHozAlign:"right" },
           {title:"Role", field:"role", responsive:4, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", responsive:0, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
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