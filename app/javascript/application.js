// Entry point for esbuild
import '@hotwired/turbo-rails'
import jquery from 'jquery'
import * as bootstrap from 'bootstrap'

// Make jQuery and Bootstrap available globally
window.jQuery = window.$ = jquery
window.bootstrap = bootstrap

// Import and configure local-time
import localTime from 'local-time'
localTime.start()

// Import application channels
import './channels'

// Import and configure Stimulus controllers
import { application } from './controllers/application'

// Import Tabulator
import { TabulatorFull as Tabulator } from 'tabulator-tables'
window.Tabulator = Tabulator

// Import TomSelect
import TomSelect from 'tom-select'
window.TomSelect = TomSelect

// Initialize Bootstrap tooltips and popovers on turbo:load
document.addEventListener('turbo:load', () => {
  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(tooltipTriggerEl => {
    new bootstrap.Tooltip(tooltipTriggerEl)
  })

  // Initialize popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.forEach(popoverTriggerEl => {
    new bootstrap.Popover(popoverTriggerEl)
  })
})
window.bootstrap = bootstrap
import {DateTime} from 'luxon'

window.DateTime = DateTime
import '@rails/request.js'
import './add_jquery'

import { initTomSelectIfNeeded } from './tomselect_helper';

import { initialiseSlugs } from './restaurants';
import { initRestaurants } from './restaurants';
import { initTips } from './tips';
import { initTestimonials } from './testimonials';
import { initTaxes } from './taxes';
import { initTablesettings } from './tablesettings';
import { initSizes } from './sizes';
import { initRestaurantlocales } from './restaurantlocales';
import { initRestaurantavailabilities } from './restaurantavailabilities';
import { initOrders } from './ordrs'; // More to do there...
import { initOrdritems } from './ordritems';
import { initMetrics } from './metrics';
import { initMenusections } from './menusections';
import { initMenus } from './menus';
import { initMenuitems } from './menuitems';
import { initMenuavailabilities } from './menuavailabilities';
import { initiInventories } from './inventories';
import { initIngredients } from './ingredients';
import { initEmployees} from './employees';
import { initDW } from './dw_orders_mv';
import { initAllergyns } from './allergyns';
import { initSmartmenus } from './smartmenus';
import { initTags } from './tags';
//import { initTracks } from './tracks';
import "./channels"

// Run on initial page load
//document.addEventListener('turbo:load', loadMetrics);

// Also run when navigating with Turbo
//document.addEventListener('turbo:render', loadMetrics);

document.addEventListener("turbo:load", () => {

    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/service-worker.js");
    }

    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    })

    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl)
    })

    $(document).ready(function () {
        window.setTimeout(function () {
            $(".alert").fadeTo(1000, 0).slideUp(1000, function () {
                $(this).remove();
            });
        }, 5000);
    });

    console.log( 'init' );

    initialiseSlugs();
    initRestaurants();
    initTips();
    initTestimonials();
    initTaxes();
    initTablesettings();
    initSizes();
    initRestaurantlocales();
    initRestaurantavailabilities();
    initOrders();
    initOrdritems();
    initMetrics();
    initMenusections();
    initMenus();
    initMenuitems();
    initMenuavailabilities();
    initiInventories();
    initIngredients();
    initEmployees();
    initDW();
    initAllergyns();
})

export function patch( url, body ) {
    fetch(url, {
        method: 'PATCH',
        headers:  {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify(body)
    });
}
export function del( url ) {
    fetch(url, {
        method: 'DELETE',
        headers:  {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
    });
}

export function validateIntegerInput(input) {
    input.value = input.value.replace(/[^0-9]/g, '');
}

window.fadeIn = function(obj) {
    $(obj).fadeIn(1000);
}

if ($("#user_plan").is(':visible')) {
    new TomSelect("#user_plan",{
    });
}