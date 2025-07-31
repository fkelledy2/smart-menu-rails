// Entry point for the application
import '@hotwired/turbo-rails'

// Import and configure jQuery
import jquery from 'jquery'
window.jQuery = window.$ = jquery

// Import other libraries
import localTime from 'local-time'
import { TabulatorFull as Tabulator } from 'tabulator-tables'
import TomSelect from 'tom-select'
import { DateTime } from 'luxon'
import '@rails/request.js'

// Make libraries available globally
window.Tabulator = Tabulator
window.TomSelect = TomSelect
window.DateTime = DateTime

// Configure local-time
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
  // Check if Bootstrap is available
  if (typeof bootstrap === 'undefined' || !bootstrap) {
    console.warn('Bootstrap not available during UI initialization');
    return;
  }

  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.forEach(tooltipTriggerEl => {
    try {
      // Destroy existing tooltip if it exists
      const existingTooltip = bootstrap.Tooltip.getInstance(tooltipTriggerEl);
      if (existingTooltip) existingTooltip.dispose();
      
      // Initialize new tooltip
      if (bootstrap.Tooltip) {
        new bootstrap.Tooltip(tooltipTriggerEl);
      }
    } catch (e) {
      console.error('Error initializing tooltip:', e);
    }
  });
  
  // Initialize popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  popoverTriggerList.forEach(popoverTriggerEl => {
    try {
      // Destroy existing popover if it exists
      const existingPopover = bootstrap.Popover.getInstance(popoverTriggerEl);
      if (existingPopover) existingPopover.dispose();
      
      // Initialize new popover
      if (bootstrap.Popover) {
        new bootstrap.Popover(popoverTriggerEl);
      }
    } catch (e) {
      console.error('Error initializing popover:', e);
    }
  });

  // Initialize modals if the function exists
  if (typeof initAccessibleModal === 'function') {
    initAccessibleModal();
  }
}

// Safe initialization function that waits for Bootstrap to be available
function safeInitializeUI() {
  if (typeof bootstrap !== 'undefined' && bootstrap) {
    initializeUI();
  } else {
    // If Bootstrap isn't loaded yet, wait for it
    document.addEventListener('bootstrap:ready', initializeUI);
  }
}

// Initialize UI when the page loads
document.addEventListener('DOMContentLoaded', safeInitializeUI);
// Re-initialize UI after Turbo navigation
document.addEventListener('turbo:load', safeInitializeUI);

// Initialize modals
function initAccessibleModal() {
  if (typeof bootstrap === 'undefined' || !bootstrap.Modal) {
    console.warn('Bootstrap Modal not available');
    return;
  }

  // Initialize modals with data-bs-toggle="modal"
  const modalElements = document.querySelectorAll('[data-bs-toggle="modal"]');
  modalElements.forEach(modalEl => {
    try {
      const target = modalEl.dataset.bsTarget;
      if (target) {
        const modal = document.querySelector(target);
        if (modal) {
          // Initialize the modal
          const bsModal = new bootstrap.Modal(modal);
          
          // Handle modal show/hide events
          modal.addEventListener('show.bs.modal', function (e) {
            // Add any additional show logic here
          });
          
          modal.addEventListener('hidden.bs.modal', function (e) {
            // Add any additional hide logic here
          });
        }
      }
    } catch (e) {
      console.error('Error initializing modal:', e);
    }
  });
}

// Make initAccessibleModal available globally
window.initAccessibleModal = initAccessibleModal;

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