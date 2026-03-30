---
name: bulk_new_modal_duplicate
description: menuitems_bulk_controller.js and menusections_bulk_controller.js used new Modal() in connect() — duplicate Bootstrap instances on Turbo navigate-back
type: feedback
---

Both bulk controllers used `new Modal(this.modalTarget)` in `connect()` without a `disconnect()` cleanup. On Turbo navigate-back, the same DOM element gets a new Bootstrap Modal instance stacked on the existing one, causing ghost modals that can't be closed.

**Why:** Same class of bug as earlier restaurantmenus_bulk and restaurants_bulk controllers.

**How to apply:** Replace `new Modal(...)` with `Modal.getOrCreateInstance(...)` and add a `disconnect()` that calls `this.bsModal.hide()`. (FIXED)
