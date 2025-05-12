document.addEventListener("turbo:load", () => {

    $(document).on("keydown", "form", function(event) {
        return event.key != "Enter";
    });

    $(".qrSlug").each(function(){
        var qrSlug = $(this).text();
        var qrCode = new QRCodeStyling({
           "type":"canvas",
           "shape":"square",
           "width":300,
           "height":300,
           "data":'https://'+$("#qrHost").text()+'/smartmenus/'+qrSlug,
           "margin":0,
           "qrOptions":{
              "typeNumber":"0",
              "mode":"Byte",
              "errorCorrectionLevel":"Q"
           },
           "imageOptions":{
              "saveAsBlob":true,
              "hideBackgroundDots":true,
              "imageSize":0.4,
              "margin":0
           },
           "dotsOptions":{
              "type":"extra-rounded",
              "color":"#000000",
              "roundSize":true
           },
           "backgroundOptions":{
              "round":0,
              "color":"#ffffff"
           },
           "image": $("#qrIcon").text(),
           "dotsOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#6a1a4c",
                 "color2":"#6a1a4c",
                 "rotation":"0"
              }
           },
           "cornersSquareOptions":{
              "type":"extra-rounded",
              "color":"#000000"
           },
           "cornersSquareOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "cornersDotOptions":{
              "type":"",
              "color":"#000000"
           },
           "cornersDotOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "backgroundOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#ffffff",
                 "color2":"#ffffff",
                 "rotation":"0"
              }
           }
        });
        document.getElementById(qrSlug).innerHTML = '';
        qrCode.append(document.getElementById(qrSlug));
    });

    $(".qrWiFi").each(function(){
        var qrSlug = $(this).text();
        var qrCode = new QRCodeStyling({
           "type":"canvas",
           "shape":"square",
           "width":300,
           "height":300,
           "data":qrSlug,
           "margin":0,
           "qrOptions":{
              "typeNumber":"0",
              "mode":"Byte",
              "errorCorrectionLevel":"Q"
           },
           "imageOptions":{
              "saveAsBlob":true,
              "hideBackgroundDots":true,
              "imageSize":0.4,
              "margin":0
           },
           "dotsOptions":{
              "type":"extra-rounded",
              "color":"#000000",
              "roundSize":true
           },
           "backgroundOptions":{
              "round":0,
              "color":"#ffffff"
           },
           "image": $("#qrIcon").text(),
           "dotsOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#6a1a4c",
                 "color2":"#6a1a4c",
                 "rotation":"0"
              }
           },
           "cornersSquareOptions":{
              "type":"extra-rounded",
              "color":"#000000"
           },
           "cornersSquareOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "cornersDotOptions":{
              "type":"",
              "color":"#000000"
           },
           "cornersDotOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#000000",
                 "color2":"#000000",
                 "rotation":"0"
              }
           },
           "backgroundOptionsHelper":{
              "colorType":{
                 "single":true,
                 "gradient":false
              },
              "gradient":{
                 "linear":true,
                 "radial":false,
                 "color1":"#ffffff",
                 "color2":"#ffffff",
                 "rotation":"0"
              }
           }
        });
        document.getElementById(qrSlug).innerHTML = '';
        qrCode.append(document.getElementById(qrSlug));
    });



    if ($("#restaurantTabs").is(':visible') || $("#newRestaurant").is(':visible')) {
      var autocomplete = new google.maps.places.Autocomplete(document.getElementById("restaurant_address1"));
      google.maps.event.addListener(autocomplete, "place_changed", function() {
        var place = autocomplete.getPlace();
        if( place ) {
           $('#restaurant_address1').val(place.formatted_address);
           for (let i = 0; i < place.address_components.length; i++) {
            if( place.address_components[i].types.includes('country') ) {
                $("#restaurant_country").val(place.address_components[i].short_name).change();
            }
            if( place.address_components[i].types.includes('postal_code') ) {
                $('#restaurant_postcode').val(place.address_components[i].long_name);
            }
            if( place.address_components[i].types.includes('administrative_area_level_3') ) {
                $('#restaurant_address2').val(place.address_components[i].long_name);
            }
            if( place.address_components[i].types.includes('administrative_area_level_2') ) {
                $('#restaurant_city').val(place.address_components[i].long_name);
            }
            if( place.address_components[i].types.includes('administrative_area_level_1') ) {
                $('#restaurant_state').val(place.address_components[i].long_name);
            }
           }
           $('#restaurant_latitude').val(place.geometry.location.lat);
           $('#restaurant_longitude').val(place.geometry.location.lng);
        }
      });
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

    if (document.getElementById("restaurant_wifiEncryptionType") != null) {
      new TomSelect("#restaurant_wifiEncryptionType",{
      });
    }
    if (document.getElementById("restaurant_wifiHidden") != null) {
      new TomSelect("#restaurant_wifiHidden",{
      });
    }
    if (document.getElementById("restaurant_status") != null) {
      new TomSelect("#restaurant_status",{
      });
    }

    if (document.getElementById("restaurant_displayImages") != null) {
      new TomSelect("#restaurant_displayImages",{
      });
    }

    if (document.getElementById("restaurant_displayImagesInPopup") != null) {
      new TomSelect("#restaurant_displayImagesInPopup",{
      });
    }

    if (document.getElementById("restaurant_allowOrdering") != null) {
      new TomSelect("#restaurant_allowOrdering",{
      });
    }

    if (document.getElementById("restaurant_inventoryTracking") != null) {
      new TomSelect("#restaurant_inventoryTracking",{
      });
    }

//    if (document.getElementById("restaurant_country") != null) {
//      new TomSelect("#restaurant_country",{
//      });
//    }

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
           {title:"Status", field:"status", formatter:status, responsive:0, minWidth: 100, hozAlign:"right", headerHozAlign:"right" }
          ],
          locale:true,
          langs:{
            "en":{
                "columns":{
                    "id":"Name", //replace the title of column name with the value "Name"
                    "address":"Address", //replace the title of column name with the value "Name"
                    "total_capacity":"Capacity", //replace the title of column name with the value "Name"
                    "status":"Status", //replace the title of column name with the value "Name"
                }
            },
            "it":{
                "columns":{
                    "id":"Nome", //replace the title of column name with the value "Name"
                    "address":"Indirizzo", //replace the title of column name with the value "Name"
                    "total_capacity":"Capacità", //replace the title of column name with the value "Name"
                    "status":"Stato", //replace the title of column name with the value "Name"
                }
            }
          }
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
    if (document.getElementById("generate-restaurant-image") != null) {
        document.getElementById("generate-restaurant-image").addEventListener("click", function(){
                let r = {
                  'genimage': {
                    'id' : $('#restaurant_genimage_id').text()
                  }
                };
                fetch('/genimages/'+$('#restaurant_genimage_id').text(), {
                    method: 'PATCH',
                    headers:  {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
                    },
                    body: JSON.stringify(r)
                });
        });
    }
})