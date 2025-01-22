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
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
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
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          ajaxURL: '/restaurants/'+restaurantId+'/employees.json',
          movableRows:true,
          columns: [
          {
              formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                  cell.getRow().toggleSelect();
              }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          {title:"", field:"sequence", visible:true, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
          {title:"Role", field:"role", responsive:5, hozAlign:"right", headerHozAlign:"right" },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "role":"Ruolo", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        restaurantEmployeeTable.on("rowMoved", function(row){
            const rows = restaurantEmployeeTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantEmployeeTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                    'employee': {
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
        restaurantEmployeeTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("employee-actions").disabled = false;
            } else {
                document.getElementById("employee-actions").disabled = true;
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