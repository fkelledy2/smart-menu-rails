import { initTomSelectIfNeeded } from './tomselect_helper';

export function initialiseSlugs() {
  $('.qrSlug').each(function () {
    const qrSlug = $(this).text();
    const qrSize = parseInt($(this).data('qrSize'), 10) || 300;
    const qrCode = new QRCodeStyling({
      type: 'canvas',
      shape: 'square',
      width: qrSize,
      height: qrSize,
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
    const qrSize = parseInt($(this).data('qrSize'), 10) || 300;
    const qrCode = new QRCodeStyling({
      type: 'canvas',
      shape: 'square',
      width: qrSize,
      height: qrSize,
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
  // Prevent duplicate global event bindings when initRestaurants is called multiple times
  // (e.g. turbo:load + turbo:frame-load for modal content)
  const alreadyBound = window.__restaurantsInitBound === true;
  if (!alreadyBound) {
    window.__restaurantsInitBound = true;

  $(document).on('keydown', 'form', function (event) {
    return event.key != 'Enter';
  });

  // Clickable rows/cards: navigate to edit when clicking background.
  // Ignore clicks on interactive elements within the row.
  $(document).on('click', '.clickable-row[data-href]', function (event) {
    const $target = $(event.target);
    if (
      $target.closest('a, button, input, select, textarea, label, .drag-handle, .form-check-input').length > 0
    ) {
      return;
    }

    const frame = this.getAttribute('data-turbo-frame');

    const primaryLink = this.querySelector('a[data-row-primary-link]');
    if (primaryLink) {
      const href = primaryLink.getAttribute('href');
      if (href && frame && window.Turbo && typeof window.Turbo.visit === 'function') {
        window.Turbo.visit(href, { frame });
        return;
      }
      primaryLink.click();
      return;
    }

    const href = this.getAttribute('data-href');
    if (!href) return;

    if (frame && window.Turbo && typeof window.Turbo.visit === 'function') {
      window.Turbo.visit(href, { frame });
      return;
    }

    window.location.href = href;
  });

  }

  const syncNewRestaurantSaveEnabled = () => {
    const saveBtn = document.getElementById('new_restaurant_save');
    if (!saveBtn) return;

    const nameEl = document.getElementById('restaurant_name');
    const addressEl = document.getElementById('restaurant_address1');
    const currencyEl = document.getElementById('restaurant_currency');

    const nameOk = (nameEl && nameEl.value && nameEl.value.trim().length > 0) || false;
    const addressOk = (addressEl && addressEl.value && addressEl.value.trim().length > 0) || false;
    const currencyOk = (currencyEl && currencyEl.value && currencyEl.value.trim().length > 0) || false;

    saveBtn.disabled = !(nameOk && addressOk && currencyOk);
  };

  // New restaurant modal: disable Save until required fields are filled.
  // Bind once globally; the handler queries current DOM so it works across turbo frame reloads.
  if (!window.__newRestaurantSaveGuardBound) {
    window.__newRestaurantSaveGuardBound = true;
    const handler = () => syncNewRestaurantSaveEnabled();
    document.addEventListener('input', handler, true);
    document.addEventListener('change', handler, true);
  }

  // Run once on each initRestaurants call (e.g. when the turbo frame loads the modal content)
  syncNewRestaurantSaveEnabled();

  const shouldInitAddressAutocomplete =
    $('#restaurantTabs').length ||
    $('#newRestaurant').length ||
    document.getElementById('restaurant_address1');

  const initAddressAutocompleteIfReady = async () => {
    if (!shouldInitAddressAutocomplete) return true;
    if (!window.google || !window.google.maps) return false;

    const dispatchAutosaveEvents = (el) => {
      if (!el) return;
      try {
        el.dispatchEvent(new Event('input', { bubbles: true }));
      } catch (e) {
        // ignore
      }
      try {
        el.dispatchEvent(new Event('change', { bubbles: true }));
      } catch (e) {
        // ignore
      }
    };

    if (!window.google.maps.places && typeof window.google.maps.importLibrary === 'function') {
      try {
        await window.google.maps.importLibrary('places');
      } catch (e) {
        console.warn('[Restaurants] google.maps.importLibrary("places") failed', e);
      }
    }

    if (!window.google.maps.places) return false;

    const addressInput = document.getElementById('restaurant_address1');
    if (!addressInput) return true;

    // Re-bind if the input element has changed between modal opens.
    const currentInputId = addressInput.dataset.autocompleteInstanceId;
    const boundInputId = window.__restaurantAutocompleteBoundInputId;
    if (window.restaurantAutocomplete && boundInputId && boundInputId === currentInputId) {
      return true;
    }

    // Ensure the input has a stable instance id for this page render.
    if (!currentInputId) {
      addressInput.dataset.autocompleteInstanceId = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
    }

    // Create the Autocomplete (stable API)
    const autocomplete = new google.maps.places.Autocomplete(addressInput, {
      fields: ['address_components', 'formatted_address', 'geometry'],
    });

    // Listen for place changes
    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace();
      if (place) {
        // Update the address field with the formatted address
        $('#restaurant_address1').val(place.formatted_address || '');
        dispatchAutosaveEvents(document.getElementById('restaurant_address1'));

        // Process address components
        if (place.address_components) {
          for (let i = 0; i < place.address_components.length; i++) {
            const component = place.address_components[i];

            if (component.types.includes('country')) {
              $('#restaurant_country').val(component.short_name).change();
              dispatchAutosaveEvents(document.getElementById('restaurant_country'));
            }
            if (component.types.includes('postal_code')) {
              $('#restaurant_postcode').val(component.long_name);
              dispatchAutosaveEvents(document.getElementById('restaurant_postcode'));
            }
            if (
              component.types.includes('sublocality_level_1') ||
              component.types.includes('neighborhood')
            ) {
              $('#restaurant_address2').val(component.long_name);
              dispatchAutosaveEvents(document.getElementById('restaurant_address2'));
            }
            if (component.types.includes('locality') || component.types.includes('postal_town')) {
              $('#restaurant_city').val(component.long_name);
              dispatchAutosaveEvents(document.getElementById('restaurant_city'));
            }
            if (component.types.includes('administrative_area_level_1')) {
              $('#restaurant_state').val(component.long_name);
              dispatchAutosaveEvents(document.getElementById('restaurant_state'));
            }
          }
        }

        if (place.geometry && place.geometry.location) {
          $('#restaurant_latitude').val(place.geometry.location.lat());
          $('#restaurant_longitude').val(place.geometry.location.lng());
          dispatchAutosaveEvents(document.getElementById('restaurant_latitude'));
          dispatchAutosaveEvents(document.getElementById('restaurant_longitude'));

          const nextPosition = {
            lat: place.geometry.location.lat(),
            lng: place.geometry.location.lng(),
          };

          const mapEl = document.getElementById('restaurant-map');
          if (mapEl && (typeof mapEl.style !== 'undefined') && mapEl.style.display === 'none') {
            mapEl.style.display = 'block';
          }

          let mapInstance = window.__restaurantMapInstance;
          const mapInstanceIsForDifferentElement =
            mapInstance && mapInstance.element && mapEl && mapInstance.element !== mapEl;

          if (
            (mapInstanceIsForDifferentElement || !mapInstance || !mapInstance.map || !mapInstance.marker) &&
            mapEl &&
            window.google &&
            window.google.maps &&
            window.google.maps.Map
          ) {
            try {
              const map = new google.maps.Map(mapEl, {
                center: nextPosition,
                zoom: 17,
                mapTypeControl: true,
                streetViewControl: true,
                fullscreenControl: true,
              });

              const marker = new google.maps.Marker({
                position: nextPosition,
                map: map,
                animation: google.maps.Animation.DROP,
              });

              window.__restaurantMapInstance = { map: map, marker: marker, element: mapEl };
              mapInstance = window.__restaurantMapInstance;
            } catch (e) {
              // ignore
            }
          }

          if (mapInstance && mapInstance.map && mapInstance.marker) {
            try {
              mapInstance.map.setCenter(nextPosition);
              mapInstance.map.setZoom(17);
              if (typeof mapInstance.marker.setPosition === 'function') {
                mapInstance.marker.setPosition(nextPosition);
              }
            } catch (e) {
              // ignore
            }
          }
        }
      }
    });

    window.restaurantAutocomplete = autocomplete;
    window.__restaurantAutocompleteBoundInputId = addressInput.dataset.autocompleteInstanceId;
    console.log('[Restaurants] Places autocomplete bound to #restaurant_address1');
    return true;
  };

  // Retry for Google script race (modal content can load before Places library is ready).
  if (shouldInitAddressAutocomplete) {
    const maxAttempts = 20;
    const attemptDelayMs = 250;
    let attempts = 0;

    const ensureGooglePlacesLoading = () => {
      if (window.google && window.google.maps && window.google.maps.places) return;
      if (window.__googleMapsInitRequested) return;
      if (typeof window.initGoogleMaps !== 'function') return;
      window.__googleMapsInitRequested = true;
      try {
        window.initGoogleMaps();
      } catch (e) {
        console.warn('[Restaurants] initGoogleMaps failed', e);
      }
    };

    const attemptInit = async () => {
      ensureGooglePlacesLoading();
      attempts += 1;
      const done = await initAddressAutocompleteIfReady();
      if (done) return;
      if (attempts >= maxAttempts) return;
      setTimeout(attemptInit, attemptDelayMs);
    };

    attemptInit();
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
  if (restaurantStatusEl && restaurantStatusEl.tagName === 'SELECT') {
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
      initialSort: [{ column: 'sequence', dir: 'asc' }],
      columns: [
        { title: 'Sequence', field: 'sequence', visible: false, sorter: 'number' },
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
