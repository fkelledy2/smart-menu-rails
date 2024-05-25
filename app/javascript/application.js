// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import "@hotwired/turbo-rails"
require("@rails/activestorage").start()
//require("trix")
//require("@rails/actiontext")
//= require jquery3
//= require jquery_ujs
//= require_tree .
//= require allow_numeric
require("local-time").start()
require("@rails/ujs").start()

import './channels/**/*_channel.js'
import "./controllers"

window.TomSelect = require('tom-select');

import * as bootstrap from "bootstrap"
import {TabulatorFull as Tabulator} from 'tabulator-tables';
window.Tabulator = Tabulator
// while we are here make sure you have
window.bootstrap = bootstrap
import {DateTime} from 'luxon'
window.DateTime = DateTime
import '@rails/request.js'
import './add_jquery'

import './allergyns'
import './employees'
import './menuitems'
import './menus'
import './menusections'
import './restaurants'
import './tablesettings'
import './tags'
import './tips'
import './taxes'
import './sizes'
import './ingredients'
import './inventories'
import './ordrs'
import './ordritems'
import './restaurantavailabilities'
import './menuavailabilities'

document.addEventListener("turbo:load", () => {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })

  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  })
})

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
import "./channels"

    if ($("#restaurantTabs").is(':visible')) {
      async function init() {
        console.log( 'gmaps: init');
        await customElements.whenDefined('gmp-map');
        const map = document.querySelector('gmp-map');
        const marker = document.querySelector('gmp-advanced-marker');
        const placePicker = document.querySelector('gmpx-place-picker');
        const infowindow = new google.maps.InfoWindow();
        map.innerMap.setOptions({
          mapTypeControl: false
        });
        placePicker.addEventListener('gmpx-placechange', () => {
          const place = placePicker.value;
          console.log( 'place: '+place.id );
          console.log( 'place: '+place.formattedAddress);
          $('#restaurant_address1').val(place.formattedAddress);
          console.log( 'place: '+JSON.stringify(place.addressComponents));
          if (!place.location) {
            window.alert(
              "No details available for input: '" + place.name + "'"
            );
            infowindow.close();
            marker.position = null;
            return;
          }
          if (place.viewport) {
            map.innerMap.fitBounds(place.viewport);
          } else {
            map.center = place.location;
            map.zoom = 17;
          }
          marker.position = place.location;
        });
      }
      document.addEventListener('DOMContentLoaded', init);
    }