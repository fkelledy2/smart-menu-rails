---
name: restaurantmenus_bulk_controller duplicate Bootstrap modal
description: restaurantmenus_bulk_controller.js used new Modal() in connect() — duplicate Bootstrap instances on Turbo navigate-back (FIXED)
type: project
---

`restaurantmenus_bulk_controller.js` called `new Modal(this.modalTarget)` in `connect()`, creating a new Bootstrap Modal instance on every Turbo page visit. On navigate-back the modal element persists in the DOM but a second instance is created, causing double-show, double backdrop, and z-index corruption.

**Why:** Same bug class as `restaurants_bulk_controller.js` (already fixed). Bootstrap requires `getOrCreateInstance` to be safe with Turbo.

**How to apply:** Every `new bootstrap.Modal(el)` call inside a Stimulus `connect()` must be `Modal.getOrCreateInstance(el)`. Fixed in `restaurantmenus_bulk_controller.js`.
