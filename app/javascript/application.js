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
import './controllers'
import MenuImportController from './controllers/menu_import_controller.js'
application.register('menu-import', MenuImportController)

// Import Tabulator
import { TabulatorFull as Tabulator } from 'tabulator-tables'
window.Tabulator = Tabulator

// Import TomSelect
import TomSelect from 'tom-select'
window.TomSelect = TomSelect

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
//import { initiInventories } from './inventories';
//import { initIngredients } from './ingredients';
import { initEmployees} from './employees';
import { initDW } from './dw_orders_mv';
import { initAllergyns } from './allergyns';
import { initSmartmenus } from './smartmenus';
import { initTags } from './tags';
//import { initTracks } from './tracks';
import "./channels"

// Function to check if all turbo frames are loaded
function allFramesLoaded() {
  const frames = document.querySelectorAll('turbo-frame');
  return Array.from(frames).every(frame => frame.loaded);
}

// Function to initialize components (singleton wrapper)
function initializeComponents() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.forEach(tooltipTriggerEl => {
      new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.forEach(popoverTriggerEl => {
      new bootstrap.Popover(popoverTriggerEl);
    });

    console.log('init');

    // Initialize all components
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
//    initiInventories();
//    initIngredients();
    initEmployees();
    initDW();
    initAllergyns();
    initSmartmenus();
}

// Enhanced turbo:load event listener with detailed logging
let turboLoadCount = 0;
const turboLoadHandler = (event) => {
  turboLoadCount++;
  console.group(`turbo:load #${turboLoadCount}`);
//  console.log('Event details:', event);
//  console.log('Document URL:', document.URL);
//  console.log('Document title:', document.title);
//  console.log('Active element:', document.activeElement);
//  console.trace('Stack trace for turbo:load');
  // Call the original initializeComponents
  initializeComponents();
  console.groupEnd();
};

// Add the event listener
document.addEventListener('turbo:load', turboLoadHandler);

// Log when the script first loads
console.log('Application JavaScript loaded. Waiting for turbo:load events...');

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

if ($("#user_plan").length) {
    new TomSelect("#user_plan",{
    });
}