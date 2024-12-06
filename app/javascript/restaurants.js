document.addEventListener("turbo:load", () => {

    if ($("#restaurantTabs").is(':visible') || $("#newRestaurant").is(':visible')) {
        const placePicker = document.querySelector('gmpx-place-picker');
            try {
                placePicker.addEventListener('gmpx-placechange', () => {
                  const place = placePicker.value;
                  if( place && place.id ) {
                      $('#restaurant_address1').val(place.formattedAddress);
                  }
                  if( place && place.addressComponents ) {
                      $('#restaurant_postcode').val("n/a");
                      for (let i = 0; i < place.addressComponents.length; i++) {
                        if( place.addressComponents[i].types.includes('country') ) {
                            $("#restaurant_country").val(place.addressComponents[i].shortText).change();
                        }
                        if( place.addressComponents[i].types.includes('postal_code') ) {
                            $('#restaurant_postcode').val(place.addressComponents[i].longText);
                        }
                      }
                  }
                  if( place && place.location ) {
                      $('#restaurant_latitude').val(place.location.lat);
                      $('#restaurant_longitude').val(place.location.lng);
                  }
                });
            } catch( err ) {
            }
    }

    if ($("#restaurantTabs").is(':visible')) {
        const pillsTab = document.querySelector('#restaurantTabs');
        const pills = pillsTab.querySelectorAll('button[data-bs-toggle="tab"]');

        pills.forEach(pill => {
          pill.addEventListener('shown.bs.tab', (event) => {
            const { target } = event;
            const { id: targetId } = target;
            savePillId(targetId);
          });
        });

        const savePillId = (selector) => {
          localStorage.setItem('activeRestaurantPillId', selector);
        };

        const getPillId = () => {
          const activePillId = localStorage.getItem('activeRestaurantPillId');
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

    if ($("#restaurant_status").is(':visible')) {
      new TomSelect("#restaurant_status",{
      });
    }

    if ($("#restaurant_displayImages").is(':visible')) {
      new TomSelect("#restaurant_displayImages",{
      });
    }

    if ($("#restaurant_allowOrdering").is(':visible')) {
      new TomSelect("#restaurant_allowOrdering",{
      });
    }

    if ($("#restaurant_inventoryTracking").is(':visible')) {
      new TomSelect("#restaurant_inventoryTracking",{
      });
    }

    if ($("#restaurant_country").is(':visible')) {
      new TomSelect("#restaurant_country",{
      });
    }

    if ($("#generate-restaurant-image").is(':visible')) {
        document.getElementById("generate-restaurant-image").addEventListener("click", function(){
            alert('down the Witches Road!');
        });
    }
    if ($("#restaurant-table").is(':visible')) {
        // Restaurants
        function status(cell, formatterParams){
            return cell.getRow().getData("data").status.toUpperCase();
        }
        function link(cell, formatterParams){
            var id = cell.getValue();
            var name = cell.getRow();
            var rowData = cell.getRow().getData("data").name;
            return "<a class='link-dark' href='/restaurants/"+id+"/edit'>"+rowData+"</a>";
        }
        var restaurantTable = new Tabulator("#restaurant-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/restaurants.json',
          columns: [
           {
             formatter:"rowSelection", titleFormatter:"rowSelection", responsive:0, width: 30, headerHozAlign:"center", hozAlign:"center", headerSort:false, cellClick:function(e, cell) {
                cell.getRow().toggleSelect();
             }
           },
           {title:"Name", field:"id", responsive:0, formatter:link, hozAlign:"left"},
           {
              title: 'Address',
              field: 'address', responsive:5,
              mutator: (value, data) =>
                  [data.address1, data.address2, data.state, data.city].filter(Boolean).join(", "),
           },
           {title:"Capacity", field:"total_capacity", responsive:4, hozAlign:"right", headerHozAlign:"right"},
           {title:"Status", field:"status", responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
        restaurantTable.on("rowSelectionChanged", function(data, rows){
            if( data.length > 0 ) {
                document.getElementById("restaurant-actions").disabled = false;
            } else {
                document.getElementById("restaurant-actions").disabled = true;
            }
        });
        document.getElementById("activate-restaurant").addEventListener("click", function(){
            const rows = restaurantTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTable.updateData([{id:rows[i].id, status:'active'}]);
                let r = {
                  'restaurant': {
                      'status': 'active'
                  }
                };
                patch( rows[i].url, r );
            }
        });
        document.getElementById("deactivate-restaurant").addEventListener("click", function(){
            const rows = restaurantTable.getSelectedData();
            for (let i = 0; i < rows.length; i++) {
                restaurantTable.updateData([{id:rows[i].id, status:'inactive'}]);
                let r = {
                  'restaurant': {
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