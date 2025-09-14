import { initTomSelectIfNeeded } from './tomselect_helper';

export function initMenusections() {

    if ($("#menusection_menu_id").length) {
      initTomSelectIfNeeded("#menusection_menu_id",{
      });
    }
    if ($("#menusection_restricted").length) {
      initTomSelectIfNeeded("#menusection_restricted",{
      });
    }

    if ($("#sectionTabs").length) {
        const pillsTab = document.querySelector('#sectionTabs');
        const pills = pillsTab.querySelectorAll('button[data-bs-toggle="tab"]');

        pills.forEach(pill => {
            pill.addEventListener('shown.bs.tab', (event) => {
                const { target } = event;
                const { id: targetId } = target;
                savePillId(targetId);
            });
        });

        const savePillId = (selector) => {
            localStorage.setItem('activeSectionPillId', selector);
        };

        const getPillId = () => {
            const activePillId = localStorage.getItem('activeSectionPillId');
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

    if ($("#menuTabs").length) {
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/menusections/"+id+"/edit'>"+rowData+"</a>";
        }
        const menuId = document.getElementById('menu-menusection-table').getAttribute('data-bs-menu');
        var menusectionTable = new Tabulator("#menu-menusection-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitColumns",
          ajaxURL: '/menus/'+menuId+'/menusections.json',
          initialSort:[
            {column:"sequence", dir:"asc"},
          ],
          movableRows:true,
          columns: [
          {
              formatter:"rowSelection", titleFormatter:"rowSelection", width: 30, frozen:true, responsive:0, headerHozAlign:"left", hozAlign:"left", headerSort:false, cellClick:function(e, cell) {
                  cell.getRow().toggleSelect();
              }
          },
          { rowHandle:true, formatter:"handle", headerSort:false, frozen:true, responsive:0, width:30, minWidth:30 },
          { title:"", field:"sequence", visible:false, formatter:"rownum", hozAlign:"right", headerHozAlign:"right", headerSort:false },
          {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},

          {title: 'Available', field: 'fromhour', mutator: (value, data) => String(data.fromhour).padStart(2, '0') + ':' + String(data.frommin).padStart(2, '0')+' - '+String(data.tohour).padStart(2, '0') + ':' + String(data.tomin).padStart(2, '0'), hozAlign:"right", headerHozAlign:"right" },
          {title: 'Restricted', field: 'restricted', hozAlign:"right", headerHozAlign:"right" },
          {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale: true,
          langs: {
            "en": {
              "pagination": {
                "first": "First",
                "first_title": "First Page",
                "last": "Last",
                "last_title": "Last Page",
                "prev": "Prev",
                "prev_title": "Previous Page",
                "next": "Next",
                "next_title": "Next Page"
              },
              "headerFilters": {
                "default": "filter column..."
              },
              "columns": {
                "id": "Name",
                "status": "Status",
                "fromhour": "Available",
                "restricted": "Restricted"
              }
            },
            "it": {
              "columns": {
                "id": "Nome",
                "status": "Stato",
                "fromhour": "Disponibile",
                "restricted": "Limitato"
              }
            }
          }
        });
        menusectionTable.on("rowMoved", function(row){
            const rows = menusectionTable.getRows();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].getData().id, sequence:rows[i].getPosition()}]);
                let mus = {
                  'menusection': {
                      'sequence': rows[i].getPosition()
                  }
                };
                fetch(rows[i].getData().url, {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(mus)
                });
            }
        });
        menusectionTable.on("rowSelectionChanged", function(data, rows){
          if( data.length > 0 ) {
            document.getElementById("menusection-actions").disabled = false;
          } else {
            document.getElementById("menusection-actions").disabled = true;
          }
        });
        document.getElementById("activate-menusection").addEventListener("click", function(){
            const rows = menusectionTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'menusection': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-menusection").addEventListener("click", function(){
            const rows = menusectionTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                menusectionTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'menusection': {
                      'status': 'inactive'
                  }
                };
                patch( rows[i].url, r );
            }
        });
    }
}

