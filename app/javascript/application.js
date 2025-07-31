// Entry point for esbuild
import '@hotwired/turbo-rails'
import jquery from 'jquery'
import * as bootstrap from 'bootstrap'
import localTime from 'local-time'
import { TabulatorFull as Tabulator } from 'tabulator-tables'
import TomSelect from 'tom-select'
import { DateTime } from 'luxon'
import '@rails/request.js'

// Make libraries available globally
window.jQuery = window.$ = jquery
window.bootstrap = bootstrap
window.Tabulator = Tabulator
window.TomSelect = TomSelect
window.DateTime = DateTime

// Import and configure local-time
localTime.start()

// Import application channels
import './channels'

// Import and configure Stimulus controllers
import { application } from './controllers/application'

// Import other JavaScript files
import './add_jquery'
import './allergyns'
import './employees'

// Initialize Bootstrap components and other UI elements
function initializeUI() {
  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(tooltipTriggerEl => {
    // Destroy existing tooltip if it exists
    const existingTooltip = bootstrap.Tooltip.getInstance(tooltipTriggerEl)
    if (existingTooltip) existingTooltip.dispose()
    
    // Initialize new tooltip
    new bootstrap.Tooltip(tooltipTriggerEl)
  })
  
  // Initialize popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.forEach(popoverTriggerEl => {
    // Destroy existing popover if it exists
    const existingPopover = bootstrap.Popover.getInstance(popoverTriggerEl)
    if (existingPopover) existingPopover.dispose()
    
    // Initialize new popover
    new bootstrap.Popover(popoverTriggerEl)
  })
}

// Initialize UI when the page loads
document.addEventListener('DOMContentLoaded', initializeUI)
// Re-initialize UI after Turbo navigation
document.addEventListener('turbo:load', initializeUI)

// Initialize TomSelect for plan selector
function initializeTomSelect() {
  if ($("#user_plan").length && !$("#user_plan").hasClass('tomselected')) {
    new TomSelect("#user_plan", {});
  }
}

document.addEventListener('turbo:load', initializeTomSelect);
document.addEventListener('DOMContentLoaded', initializeTomSelect);
import './menuitems'
import './menus'
import './smartmenus'
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
import './metrics'
//import './tracks'
import './restaurantlocales'
import './testimonials'
import './dw_orders_mv'

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

})

function patch(url, body) {
    fetch(url, {
        method: 'PATCH',
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify(body)
    });
}

import "./channels"

document.addEventListener("turbo:load", () => {
    $(document).ready(function () {
        window.setTimeout(function () {
            $(".alert").fadeTo(1000, 0).slideUp(1000, function () {
                $(this).remove();
            });
        }, 5000);
    });
});

function validateIntegerInput(input) {
    input.value = input.value.replace(/[^0-9]/g, '');
}

window.fadeIn = function(obj) {
    $(obj).fadeIn(1000);
}

if ($("#user_plan").is(':visible')) {
    new TomSelect("#user_plan",{
    });
}