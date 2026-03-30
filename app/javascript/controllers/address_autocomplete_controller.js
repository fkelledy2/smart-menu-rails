import { Controller } from '@hotwired/stimulus';

/**
 * Address Autocomplete Stimulus Controller
 *
 * Binds Google Places Autocomplete to the restaurant address field.
 * Properly awaits the Maps API via window.initGoogleMaps() rather than polling,
 * so it works reliably with Turbo frame navigation on the 2025 edit layout.
 *
 * Usage:
 *   <div data-controller="address-autocomplete">
 *     <input id="restaurant_address1" ...>
 *   </div>
 */
export default class extends Controller {
  connect() {
    this._initAutocomplete();
  }

  disconnect() {
    const input = document.getElementById('restaurant_address1');
    if (input) delete input.dataset.autocompleteAttached;
    this._autocomplete = null;
  }

  async _initAutocomplete() {
    // Load the Maps bootstrap if not already loaded
    if (typeof window.initGoogleMaps === 'function') {
      try {
        await window.initGoogleMaps();
      } catch (e) {
        console.warn('[AddressAutocomplete] initGoogleMaps failed', e);
        return;
      }
    }

    if (!window.google?.maps) return;

    // Resolve the Autocomplete constructor — try the already-loaded namespace first,
    // then fall back to importLibrary (required when loading=async).
    let AutocompleteClass = window.google.maps.places?.Autocomplete;

    if (!AutocompleteClass && typeof window.google.maps.importLibrary === 'function') {
      try {
        const placesLib = await window.google.maps.importLibrary('places');
        AutocompleteClass = placesLib?.Autocomplete ?? window.google.maps.places?.Autocomplete;
      } catch (e) {
        console.warn('[AddressAutocomplete] importLibrary("places") failed', e);
        return;
      }
    }

    if (!AutocompleteClass) return;

    const input = document.getElementById('restaurant_address1');
    if (!input) return;

    // Guard against double-init if connect() fires twice on the same element
    if (input.dataset.autocompleteAttached === 'true') return;
    input.dataset.autocompleteAttached = 'true';

    this._autocomplete = new AutocompleteClass(input, {
      fields: ['address_components', 'formatted_address', 'geometry'],
    });

    this._autocomplete.addListener('place_changed', () => this._handlePlaceChanged());
  }

  _handlePlaceChanged() {
    const place = this._autocomplete?.getPlace();
    if (!place) return;

    this._setField('restaurant_address1', place.formatted_address || '');

    if (place.address_components) {
      for (const component of place.address_components) {
        const types = component.types;
        if (types.includes('country')) {
          this._setField('restaurant_country', component.short_name);
        }
        if (types.includes('postal_code')) {
          this._setField('restaurant_postcode', component.long_name);
        }
        if (types.includes('sublocality_level_1') || types.includes('neighborhood')) {
          this._setField('restaurant_address2', component.long_name);
        }
        if (types.includes('locality') || types.includes('postal_town')) {
          this._setField('restaurant_city', component.long_name);
        }
        if (types.includes('administrative_area_level_1')) {
          this._setField('restaurant_state', component.long_name);
        }
      }
    }

    if (place.geometry?.location) {
      this._setField('restaurant_latitude', place.geometry.location.lat());
      this._setField('restaurant_longitude', place.geometry.location.lng());
    }
  }

  _setField(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    el.value = value;
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }
}
