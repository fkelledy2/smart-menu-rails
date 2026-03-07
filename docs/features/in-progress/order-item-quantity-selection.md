# Order Item Quantity Selection

**Status:** In Progress
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

The specification below reflects the **current implementation state** and the **remaining work** needed to fully close the feature.

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

## 3.2 Partially Completed

| Area | Status | Notes |
|---|---|---|
| Staff UX polish | 🟡 Partial | Staff stepper exists, but the older documentation around looping multiple POSTs is no longer correct. Current spec should reflect the single-post quantity flow. |
| Order summary modal quantity display | 🟡 Partial | `size_name` is shown, but the legacy `viewOrderModal` still lists rows individually and total calculation there still uses a simplified sum path. |
| Submitted-order quantity presentation | 🟡 Partial | Bottom-sheet submitted items show quantity, but older modal-based views are not fully aligned. |
| Kitchen/station quantity display | 🟡 Partial / unverified | This spec does not yet mark kitchen/dashboard grouping as complete. Existing consumer-facing flows are ahead of back-of-house presentation. |

## 3.3 Not Yet Completed

| Area | Status | Notes |
|---|---|---|
| Quantity grouping/merging of duplicate lines on create | ❌ Not done | Current create path still creates/updates order lines event-first, but this spec does not yet confirm duplicate open-line merge semantics for identical items. |
| Dedicated quantity update domain event | ❌ Not done | Cart quantity PATCH currently updates the record directly rather than going through an explicit order event type. |
| Full parity in legacy order modal | ❌ Not done | `viewOrderModal` still renders older row-by-row presentation and should be aligned with cart behavior. |
| Kitchen/station ticket quantity UX | ❌ Not done | Back-of-house display changes are still outstanding. |
| Quantity-based analytics | ❌ Not done | Analytics/reporting work remains open. |
| Inventory-aware updates on cart increment | ❌ Not done / not confirmed | Create is inventory-aware; PATCH quantity increase should be reviewed and hardened to enforce the same limit. |
| Direct numeric input for customer/staff quantity | ❌ Not done | Current UX is stepper-based rather than free numeric entry. |

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

---

## 6. Remaining Work

## 6.1 Backend Hardening

- Add quantity-aware validation on cart quantity increase / PATCH flows
- Confirm whether duplicate identical `opened` lines should merge automatically
- If merge semantics are desired, define exact uniqueness key:
  - `ordr_id`
  - `menuitem_id`
  - `size_name`
  - any note/customisation discriminator
- Decide whether quantity changes should emit explicit domain events instead of direct AR updates

## 6.2 UX Consistency

- Align legacy `viewOrderModal` with bottom-sheet quantity UX
- Ensure all order summaries display:
  - quantity badge
  - line total
  - size label where relevant
- Consider whether to add direct numeric input in addition to steppers

## 6.3 Back-of-House Consistency

- Update kitchen/station dashboards to show quantity clearly
- Decide whether tickets should:
  - aggregate repeated identical items
  - or show separate rows with a qty badge

## 6.4 Analytics

- Add quantity-based reporting to analytics/materialized views
- Track:
  - quantity distribution
  - high-quantity items
  - average quantity per menu item
  - revenue impact of easier multi-unit ordering

---

## 7. Recommended Next Phases

## Phase 1 — Close Functional Gaps

- Harden PATCH quantity validation against stock and bounds
- Align all summary views with cart quantity behavior
- Confirm duplicate-line merge strategy

## Phase 2 — Back-of-House Visibility

- Add quantity support to kitchen/station tickets
- Validate any downstream service assumptions around one-row-per-item vs quantity-bearing lines

## Phase 3 — Analytics & Reporting

- Add quantity metrics to reporting
- Expose order-volume insights by item and service window

## Phase 4 — Polish

- Accessibility labels for all steppers
- Animation/feedback polish
- Mobile interaction refinement

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
- [ ] Quantity changes are fully validated on all update paths
- [ ] Kitchen/station displays show quantity clearly
- [ ] Reporting includes quantity-aware analytics

## UX

- [x] Stepper controls are responsive and easy to use
- [x] Quantity changes produce visible feedback
- [x] Cart line totals update from quantity-aware pricing
- [ ] All legacy order summary surfaces are aligned with the new quantity model
- [ ] Direct numeric input is supported if still considered necessary

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

The biggest remaining value is in:

- kitchen visibility
- inventory-safe updates
- analytics
- consistency across all order surfaces

---

## 10. Summary

This feature should no longer be treated as a blank-slate request.

It is now an **in-progress feature with meaningful implementation already shipped** across:

- customer quantity selection
- staff quantity selection
- cart quantity controls
- quantity-aware backend model behavior
- quantity-aware totals and realtime state

The remaining work is primarily about **consistency, hardening, back-of-house visibility, and analytics**, not initial implementation.
