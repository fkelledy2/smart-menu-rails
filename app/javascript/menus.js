document.addEventListener("turbo:load", () => {

    if ($("#menu_status").is(':visible')) {
      new TomSelect("#menu_status",{
      });
    }

    if ($("#menu_displayImages").is(':visible')) {
      new TomSelect("#menu_displayImages",{
      });
    }

    if ($("#menu_allowOrdering").is(':visible')) {
      new TomSelect("#menu_allowOrdering",{
      });
    }

    if ($("#menu_inventoryTracking").is(':visible')) {
      new TomSelect("#menu_inventoryTracking",{
      });
    }

    if ($("#menu_restaurant_id").is(':visible')) {
      new TomSelect("#menu_restaurant_id",{
      });
    }

    if ($("#menuu").is(':visible')) {

        $(".sectionnav").on("click",function(event){
            event.preventDefault();
            $('html, body').animate({
                scrollTop: $($.attr(this, 'href')).offset().top - $("#menuu").height()
            }, 100);
        });
    }

    if ($("#menuc").is(':visible')) {
        $(".sectionnav").on("click",function(event){
            event.preventDefault();
            $('html, body').animate({
                scrollTop: $($.attr(this, 'href')).offset().top - $("#menuc").height()
            }, 100);
        });
    }

    if ($("#menu-table").is(':visible')) {
        var menuTable = new Tabulator("#menu-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menus.json',
          initialSort:[
            {column:"restaurant.name", dir:"asc"},
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          {
            title:"Restaurant", field:"restaurant.id", responsive:0, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, responsive:0, width:30, minWidth:30 },
          { title:" ", field:"sequence", formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menus/",
            }
           },
           {title:"Status", field:"status", responsive:4, hozAlign:"right", headerHozAlign:"right" },
           {title:"Created", field:"created_at", responsive:5, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", formatterParams:{
            inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat:"dd/MM/yyyy",
            invalidPlaceholder:"(invalid date)",
            }
           }
          ],
        });
        menuTable.on("rowMoved", function(row){
            const rows = menuTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menuTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mu = {
                  'menu': {
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
        menuTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("activate-row").disabled = false;
            document.getElementById("deactivate-row").disabled = false;
          } else {
            document.getElementById("activate-row").disabled = true;
            document.getElementById("deactivate-row").disabled = true;
          }
        });
        document.getElementById("activate-row").addEventListener("click", function(){
            const rows = menuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menu': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-row").addEventListener("click", function(){
            const rows = menuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menuTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menu': {
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