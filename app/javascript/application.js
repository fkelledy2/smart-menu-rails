// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import "@hotwired/turbo-rails"

require("@rails/activestorage").start()
//require("trix")
//require("@rails/actiontext")

require("local-time").start()

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