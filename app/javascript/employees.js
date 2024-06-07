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

    if ($("#restaurantTabs").is(':visible')) {
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/employees/"+id+"/edit'>"+rowData+"</a>";
        }
        const restaurantId = document.getElementById('restaurant-employee-table').getAttribute('data-bs-restaurant_id');
        var restaurantEmployeeTable = new Tabulator("#restaurant-employee-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/employees.json',
          columns: [
          {
             formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 40, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
          },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Status", field:"status", responsive:1, hozAlign:"right", headerHozAlign:"right" },
          {title:"Role", field:"role", responsive:4, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
        restaurantEmployeeTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-employee").disabled = false;
            document.getElementById("deactivate-employee").disabled = false;
          } else {
            document.getElementById("activate-employee").disabled = true;
            document.getElementById("deactivate-employee").disabled = true;
          }
        });
        document.getElementById("activate-employee").addEventListener("click", function(){
            const rows = restaurantEmployeeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantEmployeeTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'employee': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-employee").addEventListener("click", function(){
            const rows = restaurantEmployeeTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantEmployeeTable.updateData([{id:rows[i].id, status:'inactive'}]);
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