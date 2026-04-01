---
name: Party size duplicate IDs in bottom sheet vs modal
description: bindOrderCapacityUi() uses document.getElementById — both modal and bottom sheet have identical IDs, so bottom sheet +/- buttons silently update the wrong container
type: project
---

Both `_showModals.erb` (staff Bootstrap modal) and `_cart_bottom_sheet.html.erb` (customer bottom sheet) render identical element IDs: `orderCapacity`, `orderCapacityValue`, `orderCapacityDecrement`, `orderCapacityIncrement`. The `bindOrderCapacityUi()` IIFE in `ordr_commons.js` used non-scoped `document.getElementById()` calls, always resolving to the first match (the modal). Bottom sheet +/- buttons clicked fine but updated the modal's hidden input, not the bottom sheet's, so the submitted `ordercapacity` value was always 1.

**Fix**: Replaced `document.getElementById()` with a scoped `getScopeFor(el)` helper that resolves the closest `.modal-content` or `#cartStartOrderSection` ancestor, and passes that scope to all `getBoundsIn(scope)` / `setCapacityIn(scope, value)` functions.

**File fixed**: `app/javascript/ordr_commons.js` (the `bindOrderCapacityUi` IIFE)
