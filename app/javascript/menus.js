import { initTomSelectIfNeeded } from './tomselect_helper';

export function initMenus() {
    $(window).on('activate.bs.scrollspy', function () {
        clearTimeout($.data(this, 'scrollTimer'));
        $.data(this, 'scrollTimer', setTimeout(function() {
            var element = document.querySelector(".menu_sections_tab a.active");
            if( element ) {
//                element.scrollIntoView();
//                $(".menu_sections_tab a.active").click();
            }
        }, 100));
    });

    $(".sectionnav").on("click",function(event){
        event.preventDefault();
        if ($("#menuu").length) {
            $('html, body').animate({
                scrollTop: $($.attr(this, 'href')).offset().top - $("#menuu").height()
            }, 100);
        }
        if ($("#menuc").length) {
            $('html, body').animate({
                scrollTop: $($.attr(this, 'href')).offset().top - $("#menuc").height()
            }, 100);
        }
    });

    if ($("#size_size").length) {
        initTomSelectIfNeeded("#size_size",{
        });
    }

    if ($("#menu_status").length) {
        initTomSelectIfNeeded("#menu_status",{
        });
    }

    if ($("#menu_displayImages").length) {
        initTomSelectIfNeeded("#menu_displayImages",{
        });
    }

    if ($("#menu_displayImagesInPopup").length) {
        initTomSelectIfNeeded("#menu_displayImagesInPopup",{
        });
    }

    if ($("#menu_allowOrdering").length) {
        initTomSelectIfNeeded("#menu_allowOrdering",{
        });
    }

    if ($("#menu_inventoryTracking").length) {
        initTomSelectIfNeeded("#menu_inventoryTracking",{
        });
    }

    if ($("#menu_restaurant_id").length) {
        initTomSelectIfNeeded("#menu_restaurant_id",{
        });
    }

    if ($("#menuTabs").length) {
        const pillsTab = document.querySelector('#menuTabs');
        const pills = pillsTab.querySelectorAll('button[data-bs-toggle="tab"]');

        pills.forEach(pill => {
            pill.addEventListener('shown.bs.tab', (event) => {
                const { target } = event;
                const { id: targetId } = target;
                savePillId(targetId);
            });
        });

        const savePillId = (selector) => {
            localStorage.setItem('activeMenuPillId', selector);
        };

        const getPillId = () => {
            const activePillId = localStorage.getItem('activeMenuPillId');
            // if local storage item is null, show default tab
            if (!activePillId) return;
            // call 'show' function
            const someTabTriggerEl = document.querySelector(`#${activePillId}`)
            const tab = new bootstrap.Tab(someTabTriggerEl);
            tab.show();
        };
        // get pill id on load
        getPillId();
    }


    if ($("#menu-table").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        var menuTable = new Tabulator("#menu-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/menus.json',
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
          {
            title:"Restaurant", field:"restaurant.id", responsive:0, formatter:"link", formatterParams: {
                labelField:"restaurant.name",
                urlPrefix:"/restaurants/",
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/menus/",
            }
           },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
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
    }

    if ($("#restaurantTabs").length) {
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/menus/"+id+"/edit'>"+rowData+"</a>";
        }
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        const menuTableElement = document.getElementById('restaurant-menu-table');
        if (!menuTableElement) return; // Exit if element doesn't exist
        const restaurantId = menuTableElement.getAttribute('data-bs-restaurant_id');
        var restaurantMenuTable = new Tabulator("#restaurant-menu-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants/'+restaurantId+'/menus.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
            formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
               cell.getRow().toggleSelect();
            }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", responsive:5, hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", formatter:link, hozAlign:"left"},
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            },
            "en":{
                "columns":{
                    "id":"Name", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            }
          }
        });
        restaurantMenuTable.on("rowMoved", function(row){
            const rows = restaurantMenuTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                restaurantMenuTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
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
        restaurantMenuTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("menu-actions").disabled = false;
            } else {
                document.getElementById("menu-actions").disabled = true;
            }
        });
        document.getElementById("activate-menu").addEventListener("click", function(){
            const rows = restaurantMenuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantMenuTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menu': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-menu").addEventListener("click", function(){
            const rows = restaurantMenuTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantMenuTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menu': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
    }
}
