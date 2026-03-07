# Order Item Quantity Selection

**Status:** Complete
**Priority:** High
**Category:** Menu Enhancements / Ordering UX / Order Data Model
**Target:** 2026

---

## 1. Overview

This feature adds quantity-aware ordering to smartmenu flows so guests and staff can add multiple units of the same item without creating repeated manual interactions.

The original request began as a pure UX enhancement. Since then, the implementation has evolved into a broader change touching:

- customer add-to-order modal UX
- staff quick-add UX
- `Ordritem` data model
- cart rendering and cart quantity controls
- totals and realtime state payloads
- inventory validation on create
- inventory validation on update
- legacy modal and station-ticket quantity presentation
- quantity-aware analytics payloads

The specification below reflects the **final implemented state** of the feature and a short list of optional follow-on enhancements that are no longer required to ship quantity selection.

---

## 2. User Story

> **As a customer or employee adding an item to an order, I want to select the quantity to add in one action, instead of repeating the same add flow multiple times.**

---

## 3. Current Implementation Status

## 3.1 Completed

| Area | Status | Notes |
|---|---|---|
| `Ordritem.quantity` data model | ✅ Done | `Ordritem` now validates `quantity` from 1–99 and exposes `total_price`, `increase_quantity`, `decrease_quantity`. |
| Backend create accepts `quantity` | ✅ Done | `OrdritemsController#create` accepts `quantity`, clamps it to `1..99`, emits event payload with `qty`, and checks inventory against requested quantity. |
| Backend update accepts `quantity` | ✅ Done | `OrdritemsController#update` permits quantity updates and cart +/- flows PATCH the record directly. |
| Staff quantity selection | ✅ Done | `quick_add_controller.js` provides a stepper before add. |
| Customer quantity selection in add-item modal | ✅ Done | `ordr_commons.js` provides modal +/- quantity controls with default `1` and max `99`. |
| Add-to-order request carries quantity | ✅ Done | `ordr_commons.js` posts a single `ordritem` payload with `quantity`. |
| Size-aware quantity flow | ✅ Done | Quantity works with `size_name` and sized items. |
| Cart quantity controls | ✅ Done | `_cart_bottom_sheet.html.erb` includes +/- controls; `ordr_commons.js` patches quantity or removes item when decrementing from `1`. |
| Cart quantity display | ✅ Done | Cart shows quantity badge and line total using `item.total_price`. |
| State payload includes quantity | ✅ Done | `SmartmenuState` includes `quantity` and `size_name` per order item. |
| Totals respect quantity | ✅ Done | `SmartmenuState.totals_for` and cart rendering use `ordritemprice * quantity`. |
| Inventory validation on create | ✅ Done | Requested quantity is checked against `Inventory.currentinventory` when inventory tracking is enabled. |
| Inventory-aware updates on cart increment | ✅ Done | `OrdritemsController#update` now clamps quantity to `1..99`, rejects increases that exceed available stock, and adjusts inventory by quantity delta. |
| Legacy order modal quantity totals | ✅ Done | `viewOrderModal` now shows quantity badges and uses `Ordritem#total_price` for line totals and the total row. |
| Quantity grouping/merging of duplicate lines on create | ✅ Done | `OrderEventProjector` merges identical `opened` items with the same `menuitem` and `size_name` into one row and clamps merged quantity at `99`. |
| Kitchen/station quantity display | ✅ Done | Kitchen and bar station ticket cards render quantity badges for items with `quantity > 1` and preserve `size_name` display. |
| Quantity-based analytics | ✅ Done | Restaurant insights now aggregate `quantity_sold` from `ordritems.quantity`, and cached order detail payloads expose real item quantities. |
| Direct numeric input for customer/staff quantity | ✅ Done | Staff quick-add and the add-item modal now support typed quantity entry alongside the existing +/- steppers, with `1..99` clamping. |

## 3.2 Optional Follow-On Enhancements

| Area | Status | Notes |
|---|---|---|
| Dedicated quantity update domain event | Optional | Cart quantity PATCH currently updates the record directly rather than going through a separate order event type. |

---

## 4. Current Product Behavior

## 4.1 Customer Flow

### Add item modal

Customers can now:

- open an item
- increase or decrease quantity in the add-item modal
- see modal total update based on `unit price × quantity`
- confirm once to create the item with the selected quantity

### Cart

Customers can now:

- see item quantity in the cart
- increase quantity
- decrease quantity
- remove the item entirely by decrementing from `1`
- see line totals derived from `quantity × price`

## 4.2 Staff Flow

Staff can now:

- use the quick-add stepper on menu items
- carry the chosen quantity into the add-item flow
- submit a single quantity-aware add request

## 4.3 Backend / State

The backend now:

- accepts `quantity` in `ordritem_params`
- validates `Ordritem.quantity`
- computes `Ordritem#total_price`
- includes quantity in smartmenu state JSON
- uses quantity-aware totals for order/cart rendering
- validates PATCH quantity increases against available inventory when stock tracking is enabled
- adjusts inventory by quantity delta when quantity changes
- aggregates analytics quantities from `ordritems.quantity`
- exposes real quantities in cached order detail payloads

---

## 5. Key Technical Notes

## 5.1 Current Data Model

`Ordritem` is now the canonical quantity-bearing line item.

Relevant fields/behavior:

- `quantity`
- `ordritemprice`
- `size_name`
- `status`
- `line_key`
- `total_price`

This means the older plan to introduce a brand new quantity concept is no longer pending; it has already been partially delivered in the existing `Ordritem` model.

## 5.2 Current Frontend Touchpoints

Relevant files already participating in this feature:

- `app/javascript/controllers/quick_add_controller.js`
- `app/javascript/ordr_commons.js`
- `app/javascript/ordrs.js`
- `app/javascript/controllers/state_controller.js`
- `app/views/smartmenus/_cart_bottom_sheet.html.erb`
- `app/views/smartmenus/_showModals.erb`
- `app/views/smartmenus/_showMenuitemStaff.erb`
- `app/views/smartmenus/_showMenuitemSizes.erb`
- `app/views/smartmenus/_showMenuitemHorizontalActionBar.erb`

## 5.3 Current Backend Touchpoints

Relevant backend files already participating in this feature:

- `app/models/ordritem.rb`
- `app/controllers/ordritems_controller.rb`
- `app/presenters/smartmenu_state.rb`
- `app/services/order_event_projector.rb`
- `app/models/menuitem.rb`
- `app/services/restaurant_insights_service.rb`
- `app/services/advanced_cache_service.rb`

---

## 6. Optional Future Enhancements

## 6.1 Event Model

- Decide whether quantity changes should emit explicit domain events instead of direct AR updates

## 6.2 UX Options

- Consider whether to add direct numeric input in addition to steppers

- Consider deeper reporting such as:
  - quantity distribution
  - high-quantity items
  - average quantity per menu item
  - revenue impact of easier multi-unit ordering

---

## 7. Validation Summary

- `OrderEventProjector` tests confirm duplicate open-line merge semantics and quantity clamping.
- Controller tests confirm create-time and update-time inventory enforcement.
- Controller/service tests confirm analytics and cached payloads now reflect real quantities.
- Focused JavaScript syntax checks confirm the quick-add controller and shared order bindings remain valid after adding typed quantity entry.
- UI templates for cart, legacy modal, and station tickets all render quantity-aware labels/totals.

- Focus any next work on optional ergonomics or deeper reporting, not core quantity-selection correctness.

---

## 8. Acceptance Criteria

## Functional

- [x] Users can select quantity between `1` and `99` when adding items
- [x] Quantity defaults to `1`
- [x] Customer add-item modal supports quantity changes
- [x] Staff quick-add supports quantity changes
- [x] Cart shows quantity and line totals
- [x] Cart quantity can be incremented and decremented
- [x] Order totals respect quantity
- [x] Quantity is represented in smartmenu state payloads
- [x] Quantity changes are fully validated on all update paths
- [x] Kitchen/station displays show quantity clearly
- [x] Reporting includes quantity-aware analytics

## UX

- [x] Stepper controls are responsive and easy to use
- [x] Quantity changes produce visible feedback
- [x] Cart line totals update from quantity-aware pricing
- [x] All legacy order summary surfaces are aligned with the new quantity model
- [x] Direct numeric input is supported if still considered necessary

---

## 9. Business Value

### User experience

- Faster multi-item ordering
- Less repetitive tapping
- Better cart clarity
- Better handling of sized items with quantity

### Operations

- Faster staff order entry
- Cleaner quantity-aware state model
- Better foundation for analytics and inventory controls

### Remaining value unlock

The biggest optional follow-on value is in:

- richer reporting
- event-model consistency
- optional alternate input patterns

---

## 10. Summary

This feature should no longer be treated as a blank-slate request or as still open for core implementation.

It is now a **completed feature** with shipped quantity support across:

- customer quantity selection
- staff quantity selection
- cart quantity controls
- quantity-aware backend model behavior
- quantity-aware totals and realtime state

The core quantity-selection feature is complete. Any remaining work is optional product polish or broader platform follow-on work rather than a blocker for this feature.
