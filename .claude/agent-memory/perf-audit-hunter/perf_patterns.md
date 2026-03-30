---
name: Recurring performance patterns
description: Hot spots and anti-patterns found during the March 2026 performance audit of Smart Menu
type: project
---

## In-memory Ruby aggregation on ActiveRecord scopes (CRITICAL)

`AdvancedCacheService` (app/services/advanced_cache_service.rb) had multiple instances of
`.sum { |o| o.gross || 0 }` and `.count { |e| e.status == 'active' }` against
ActiveRecord relations. These materialise the entire result set into Ruby objects.
Fixed by using SQL aggregates: `.sum('COALESCE(gross, 0)')`, `.where(status: 'active').count`.

## Double-fetch of Menuitem in MenuitemsController (CRITICAL)

`before_action :set_menuitem` AND `before_action :set_currency` both called
`Menuitem.find(params[:id])` independently, firing 2 DB queries for the same record on
every single-record action (show/edit/update/destroy/analytics/image_status).
Additionally, `update` action re-fetched via `@menuitem = Menuitem.find(params[:id])` inside
the action body even after set_menuitem had already loaded it.

Fix: `set_currency` now re-uses `@menuitem` if already assigned; `set_menuitem` loads with
`includes(menusection: { menu: :restaurant })` so the restaurant chain is never lazy-loaded.

## N+1 in reorder actions (MAJOR)

Both `MenuitemsController#reorder` and `MenusectionsController#reorder` iterated the
`params[:order]` array and called `.find(item[:id])` + `update_column` per item — one
SELECT + one UPDATE per row in the payload.

Fix: validate all IDs with a single `WHERE id IN (...)` then issue individual
`update_all` calls inside one transaction (eliminates the per-row SELECT).

## N+1 COUNT in cached_menu_with_items (CRITICAL)

`menu.menusections.sum { |s| s.menuitems.count }` fired one COUNT query per section.
Fixed with: `Menuitem.where(menusection_id: section_ids).count` — single query regardless
of section count.

## Per-order COUNT N+1 in cached_restaurant_orders (MAJOR)

`order.ordritems.count` inside the orders `.map` loop fired one COUNT per order (100 orders
= 100 COUNT queries). Fixed by using `order.ordritems_count` counter_cache column.

## Tax queries inside orders loop (MAJOR)

`cached_restaurant_orders` called `restaurant.taxes.order(:sequence)` inside the per-order
loop when `include_calculations: true`. This fired one SELECT per order.
Fix: pre-load taxes via `.pluck` once outside the loop.

## whiskey_ambassador_ready? iterates menus in Ruby (MAJOR)

`menus.any? { |menu| menu.menuitems.where(...).count >= 10 }` loads all menus and fires one
COUNT per menu. Fixed with a single SQL GROUP BY + HAVING query using EXISTS.

## menusections set_menusection issues a COUNT via menuitems association (MAJOR)

`@menusection.menu.menuitems.count` fired a COUNT(*) query on every set_menusection call
(edit/show/update/destroy). Fixed by reading `menu.menuitems_count` counter_cache column.

## Restaurant#total_capacity loads all tablesettings (MINOR)

`tablesettings.sum(&:capacity)` loads all tablesetting records into Ruby.
Fixed with `tablesettings.sum(:capacity)` (SQL SUM).

## AdvancedCacheService cached_restaurant_dashboard in-memory staff count (MAJOR)

`staff.count { |e| e.status == 'active' }` loaded all employees to count active ones.
`active_menus.sort_by(&:updated_at).last(3)` loaded all active menus to get 3 recent ones.
Fixed with SQL: `staff.where(status: 'active').count` and `order(updated_at: :desc).limit(3)`.

## Double-fetch of Restaurant in OrdrsController (CRITICAL — fixed second pass)

`OrdrsController#set_restaurant` AND `#set_currency` both called `Restaurant.find(params[:restaurant_id])`
independently. Same dual-fetch existed in `OrdritemsController` (`set_ordritem` + `set_currency` both
called `Ordritem.find(params[:id])`).

Fix pattern: use `@resource ||= Model.find(params[:id])` in the second before_action so it short-circuits
when the resource is already assigned.

## cached_user_activity per-restaurant N+1 (CRITICAL — fixed second pass)

`cached_user_activity` iterated `user.restaurants.each` and inside the loop issued separate
`restaurant.ordrs.where(...)` + `restaurant.menus.where(...)` queries per restaurant.
Revenue was summed with `.sum { |o| o.gross }` (Ruby enumeration loading all order rows).

Fix: one batched GROUP BY + SUM query for order stats, one batched GROUP BY COUNT for menu updates —
both keyed by restaurant_id, processed via a hash lookup outside the loop.

## cached_user_all_orders ordritems.count N+1 (CRITICAL — fixed second pass)

Line 508 called `order.ordritems.count` inside the per-order map loop. Fixed to use
`order.ordritems_count` (the counter-cache column).

## cached_order_with_details missing eager load (CRITICAL — fixed second pass)

`Ordr.find(order_id)` was called without includes, then `order.ordritems.map { |i| i.menuitem&.name }`
triggered N individual menuitem SELECTs. Tax calculation used `restaurant.taxes.order(:sequence)` which
creates Tax ActiveRecord objects unnecessarily.

Fix: `Ordr.includes(:restaurant, :menu, ordritems: :menuitem).find_by(id:)` + pluck taxes as `[percentage, type]` pairs.

## RecalculateMenuitemCostsJob N+1 find_by per item (MAJOR — fixed second pass)

The job iterated `menuitem_ids.each { |id| Menuitem.find_by(id: id); menuitem.menuitem_costs.where(...).any? }`.
Fixed to batch-load: `Menuitem.where(id: menuitem_ids).includes(:menuitem_costs)` then filter in Ruby on the
already-loaded association.

## serialize_order_basic uses ordritems.count not counter-cache (MAJOR — fixed second pass)

`serialize_order_basic` called `order.fetch_ordritems.count` / `order.ordritems.count`. Fixed to read
`order.ordritems_count` (counter-cache column). Same fix applied to `calculate_daily_breakdown`.

## cached_section_items_with_details lazy-loads menu (MINOR — fixed second pass)

`menusection.menu.id` on line 333 triggered a lazy-load SELECT on menus every time the cache was cold.
Fixed by `Menusection.includes(:menu).find(menusection_id)`.

## cached_menuitem_with_analytics lazy-loads 3-table chain (MINOR — fixed second pass)

`menuitem.menusection.menu.restaurant` triggered 3 sequential lazy-load SELECTs.
Fixed by `Menuitem.includes(menusection: { menu: :restaurant }).find_by(id:)`.

## High-traffic tables (be careful with queries)
- `ordrs` — counter columns: ordritems_count, ordrparticipants_count; use with restaurant_id scope
- `ordritems` — always scope via ordr_id; has counter_cache on menuitem
- `menuitems` — use menusection_id scopes; partial indexes on (archived = false) are key
- `menuitemlocales` — case-insensitive locale lookups need functional index (added)

**Why:** These are the write-hot tables during active dining sessions.
**How to apply:** Always use SQL aggregates; never iterate in Ruby for count/sum/select on these.

## Performance test suite location
- `test/performance/perf_audit_2026_test.rb` — first-pass audit tests (7 tests)
- `test/performance/perf_audit_2026b_test.rb` — second-pass audit tests (14 tests)
- All use `ActiveSupport::Notifications` to count SQL queries (no extra gems required)
- Base pattern: subscribe to `sql.active_record`, count/filter, assert upper bound
