import { initTomSelectIfNeeded } from './tomselect_helper';

export function initialiseSlugs() {
  $('.qrSlug').each(function () {
    const qrSlug = $(this).text();
    const qrCode = new QRCodeStyling({
      type: 'canvas',
      shape: 'square',
      width: 300,
      height: 300,
      data: 'https://' + $('#qrHost').text() + '/smartmenus/' + qrSlug,
      margin: 0,
      qrOptions: {
        typeNumber: '0',
        mode: 'Byte',
        errorCorrectionLevel: 'Q',
      },
      imageOptions: {
        saveAsBlob: true,
        hideBackgroundDots: true,
        imageSize: 0.4,
        margin: 0,
      },
      dotsOptions: {
        type: 'extra-rounded',
        color: '#000000',
        roundSize: true,
      },
      backgroundOptions: {
        round: 0,
        color: '#ffffff',
      },
      image: $('#qrIcon').text(),
      dotsOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#6a1a4c',
          color2: '#6a1a4c',
          rotation: '0',
        },
      },
      cornersSquareOptions: {
        type: 'extra-rounded',
        color: '#000000',
      },
      cornersSquareOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      cornersDotOptions: {
        type: '',
        color: '#000000',
      },
      cornersDotOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      backgroundOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#ffffff',
          color2: '#ffffff',
          rotation: '0',
        },
      },
    });
    document.getElementById(qrSlug).innerHTML = '';
    qrCode.append(document.getElementById(qrSlug));
  });

  $('.qrWiFi').each(function () {
    const qrSlug = $(this).text();
    const qrCode = new QRCodeStyling({
      type: 'canvas',
      shape: 'square',
      width: 300,
      height: 300,
      data: qrSlug,
      margin: 0,
      qrOptions: {
        typeNumber: '0',
        mode: 'Byte',
        errorCorrectionLevel: 'Q',
      },
      imageOptions: {
        saveAsBlob: true,
        hideBackgroundDots: true,
        imageSize: 0.4,
        margin: 0,
      },
      dotsOptions: {
        type: 'extra-rounded',
        color: '#000000',
        roundSize: true,
      },
      backgroundOptions: {
        round: 0,
        color: '#ffffff',
      },
      image: $('#qrIcon').text(),
      dotsOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#6a1a4c',
          color2: '#6a1a4c',
          rotation: '0',
        },
      },
      cornersSquareOptions: {
        type: 'extra-rounded',
        color: '#000000',
      },
      cornersSquareOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      cornersDotOptions: {
        type: '',
        color: '#000000',
      },
      cornersDotOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#000000',
          color2: '#000000',
          rotation: '0',
        },
      },
      backgroundOptionsHelper: {
        colorType: {
          single: true,
          gradient: false,
        },
        gradient: {
          linear: true,
          radial: false,
          color1: '#ffffff',
          color2: '#ffffff',
          rotation: '0',
        },
      },
    });
    document.getElementById(qrSlug).innerHTML = '';
    qrCode.append(document.getElementById(qrSlug));
  });
}

export function initRestaurants() {
  $(document).on('keydown', 'form', function (event) {
    return event.key != 'Enter';
  });
  if (
    ($('#restaurantTabs').length || $('#newRestaurant').length) &&
    window.google &&
    window.google.maps &&
    window.google.maps.places
  ) {
    const addressInput = document.getElementById('restaurant_address1');
    // Create the AutocompleteElement
    const autocomplete = new google.maps.places.PlaceAutocompleteElement({
      inputElement: addressInput,
      componentRestrictions: { country: [] },
      fields: ['address_components', 'formatted_address'],
    });

    // Listen for place changes
    autocomplete.addEventListener('place_changed', () => {
      const place = autocomplete.place;
      if (place) {
        // Update the address field with the formatted address
        $('#restaurant_address1').val(place.formatted_address || '');

        // Process address components
        if (place.address_components) {
          for (let i = 0; i < place.address_components.length; i++) {
            const component = place.address_components[i];

            if (component.types.includes('country')) {
              $('#restaurant_country').val(component.short_name).change();
            }
            if (component.types.includes('postal_code')) {
              $('#restaurant_postcode').val(component.long_name);
            }
            if (
              component.types.includes('sublocality_level_1') ||
              component.types.includes('neighborhood')
            ) {
              $('#restaurant_address2').val(component.long_name);
            }
            if (component.types.includes('locality') || component.types.includes('postal_town')) {
              $('#restaurant_city').val(component.long_name);
            }
            if (component.types.includes('administrative_area_level_1')) {
              $('#restaurant_state').val(component.long_name);
            }
          }
        }
      }
    });

    // Make the autocomplete element available globally if needed elsewhere
    window.restaurantAutocomplete = autocomplete;
  }

  if ($('#restaurantTabs').length) {
    const pillsTab = document.querySelector('#restaurantTabs');
    const pills = pillsTab.querySelectorAll('button[data-bs-toggle="tab"]');

    pills.forEach((pill) => {
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
      const someTabTriggerEl = document.querySelector(`#${activePillId}`);
      const tab = new bootstrap.Tab(someTabTriggerEl);
      tab.show();
    };
    // get pill id on load
    getPillId();
  }

  const wifiEncryptionTypeEl = document.getElementById('restaurant_wifiEncryptionType');
  if (wifiEncryptionTypeEl) {
    initTomSelectIfNeeded(wifiEncryptionTypeEl, {});
  }
  const wifiHiddenEl = document.getElementById('restaurant_wifiHidden');
  if (wifiHiddenEl) {
    initTomSelectIfNeeded(wifiHiddenEl, {});
  }
  const restaurantStatusEl = document.getElementById('restaurant_status');
  if (restaurantStatusEl) {
    initTomSelectIfNeeded(restaurantStatusEl, {});
  }

  // Note: displayImages, displayImagesInPopup, allowOrdering, and inventoryTracking
  // are now rendered as Bootstrap switches in the settings section
  // and should not be initialized with TomSelect

  if ($('#restaurant-table').length) {
    // Check if user is authenticated before loading restaurant data - multiple checks
    const csrfToken = document.querySelector("meta[name='csrf-token']");
    const isHomePage = window.location.pathname === '/';
    const hasUserMenu = document.querySelector('.navbar .dropdown-toggle'); // User dropdown in navbar
    const hasLoginForm = document.querySelector('form[action*="sign_in"]'); // Login form present

    // If we're on the home page and there's no user menu, user is likely logged out
    if (isHomePage && !hasUserMenu) {
      console.log(
        '[Restaurants] User appears to be logged out (home page, no user menu), skipping restaurant table initialization'
      );
      return;
    }

    // If there's a login form, user is definitely logged out
    if (hasLoginForm) {
      console.log(
        '[Restaurants] Login form detected, user not authenticated, skipping restaurant table initialization'
      );
      return;
    }

    // If no CSRF token, definitely not authenticated
    if (!csrfToken) {
      console.log(
        '[Restaurants] No CSRF token, user not authenticated, skipping restaurant table initialization'
      );
      return;
    }

    // Restaurants
    function status(cell, formatterParams) {
      return cell.getRow().getData('data').status.toUpperCase();
    }
    function link(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').name;
      return "<a class='link-dark' href='/restaurants/" + id + "/edit'>" + rowData + '</a>';
    }

    const restaurantTable = new Tabulator('#restaurant-table', {
      dataLoader: false,
      maxHeight: '100%',
      responsiveLayout: true,
      layout: 'fitDataStretch',
      ajaxURL: '/restaurants.json',
      columns: [
        {
          formatter: 'rowSelection',
          titleFormatter: 'rowSelection',
          responsive: 0,
          width: 30,
          headerHozAlign: 'center',
          hozAlign: 'center',
          headerSort: false,
          cellClick: function (e, cell) {
            cell.getRow().toggleSelect();
          },
        },
        { title: 'Name', field: 'id', responsive: 0, formatter: link, hozAlign: 'left' },
        {
          title: 'Address',
          field: 'address',
          responsive: 5,
          mutator: (value, data) =>
            [data.address1, data.address2, data.state, data.city].filter(Boolean).join(', '),
        },
        {
          title: 'Capacity',
          field: 'total_capacity',
          responsive: 4,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
        {
          title: 'Status',
          field: 'status',
          formatter: status,
          responsive: 0,
          minWidth: 100,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
      ],
      locale: true,
      langs: {
        en: {
          columns: {
            id: 'Name', //replace the title of column name with the value "Name"
            address: 'Address', //replace the title of column name with the value "Name"
            total_capacity: 'Capacity', //replace the title of column name with the value "Name"
            status: 'Status', //replace the title of column name with the value "Name"
          },
        },
        it: {
          columns: {
            id: 'Nome', //replace the title of column name with the value "Name"
            address: 'Indirizzo', //replace the title of column name with the value "Name"
            total_capacity: 'Capacità', //replace the title of column name with the value "Name"
            status: 'Stato', //replace the title of column name with the value "Name"
          },
        },
      },
    });

    restaurantTable.on('rowSelectionChanged', function (data, rows) {
      if (data.length > 0) {
        document.getElementById('restaurant-actions').disabled = false;
      } else {
        document.getElementById('restaurant-actions').disabled = true;
      }
    });
    document.getElementById('activate-restaurant').addEventListener('click', function () {
      const rows = restaurantTable.getSelectedData();
      for (let i = 0; i < rows.length; i++) {
        restaurantTable.updateData([{ id: rows[i].id, status: 'active' }]);
        const r = {
          restaurant: {
            status: 'active',
          },
        };
        patch(rows[i].url, r);
      }
    });
    document.getElementById('deactivate-restaurant').addEventListener('click', function () {
      const rows = restaurantTable.getSelectedData();
      for (let i = 0; i < rows.length; i++) {
        restaurantTable.updateData([{ id: rows[i].id, status: 'inactive' }]);
        const r = {
          restaurant: {
            status: 'inactive',
          },
        };
        patch(rows[i].url, r);
      }
    });
  }
  if (document.getElementById('generate-restaurant-image') != null) {
    document.getElementById('generate-restaurant-image').addEventListener('click', function () {
      const r = {
        genimage: {
          id: $('#restaurant_genimage_id').text(),
        },
      };
      fetch('/genimages/' + $('#restaurant_genimage_id').text(), {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
        },
        body: JSON.stringify(r),
      });
    });
  }
}
