---
name: Unguarded Restaurant.find in multiple controllers
description: beverage_review_queues, alcohol_order_events, whiskey_imports, allergyns, taxes, tablesettings use Restaurant.find without rescue — unhandled 500 on bad/missing restaurant_id
type: project
---

Controllers that call `Restaurant.find(params[:restaurant_id])` (or a nil-source variant) without a rescue block, resulting in an unhandled `ActiveRecord::RecordNotFound` (500) when the restaurant_id is invalid, stale, or absent:

- `beverage_review_queues_controller.rb` line 67 — `rid` can be nil if both params[:id] and params[:restaurant_id] absent
- `alcohol_order_events_controller.rb` line 27 — `set_restaurant`
- `whiskey_imports_controller.rb` line 36 — same nil-source pattern as beverage_review_queues
- `allergyns_controller.rb` lines 135, 179 — bulk_update, reorder
- `taxes_controller.rb` lines 15, 32, 128, 172 — index, new, bulk_update, reorder
- `tablesettings_controller.rb` lines 22, 53, 139, 147, 211 — index (authenticated), new, new_bulk_create, bulk_create, reorder

There is no global `rescue_from ActiveRecord::RecordNotFound` in ApplicationController.

Fix pattern: replace `Restaurant.find(params[:restaurant_id])` with `Restaurant.find_by(id: params[:restaurant_id])` plus a nil guard that returns 404 or redirects.

**Why:** These controllers were scaffolded or ported without adding the standard find_by nil guard. The absence of a global rescue_from means this reaches users as a 500.

**How to apply:** Any time a controller is audited, check all `.find(params[...])` calls — these must have a rescue or be converted to find_by with an explicit not-found path.
