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

## serialize_menu uses fetch_menusections.count instead of counter cache (MINOR — fixed third pass)

`serialize_menu` called `menu.fetch_menusections.count` — materialised all sections via
IdentityCache proxy then counted in Ruby. Fixed to `menu.menusections_count` (counter cache column).

## cached_user_all_employees N+1 per restaurant (MAJOR — fixed third pass)

Iterated `user.restaurants.each` and issued one `restaurant.employees.where(...)` per restaurant.
Fixed to single batch: `Employee.where(restaurant_id: restaurant_ids).includes(:user)`.

## calculate_popular_items N+1 + per-item Ruby iteration (CRITICAL — fixed third pass)

Called `order.ordritems` then `item.menuitem` for each item, across every order in the range.
O(orders * ordritems * menuitem) Ruby work. Fixed with single SQL:
`Ordritem.joins(:menuitem).where(ordr_id: orders.select(:id)).group('menuitems.name').pluck(...)`.

## calculate_order_trends / daily_breakdown / status_distribution / peak_hours load rows (MAJOR — fixed third pass)

All four private helpers passed an `orders` AR relation and called `.group_by { |o| o.created_at.to_date }`
etc. — materialised all order rows into Ruby. Fixed with SQL GROUP BY + pluck. Required
`.unscope(:order)` because `restaurant.ordrs` has `reorder(orderedAt: :desc)` which conflicts
with GROUP BY when aggregating. Always call `.unscope(:order)` before GROUP BY aggregates on ordrs.

## analyze_menu_item_performance O(n*m) flat_map inside item loop (CRITICAL — fixed third pass)

Inner loop called `orders.flat_map { |o| o.fetch_ordritems }` for each menu item — O(sections * items * orders)
Ruby + DB work. Fixed with two SQL queries: pluck menu items, then one GROUP BY aggregate on ordritems.

## cached_individual_order_analytics Ruby sum over similar orders (MAJOR — fixed third pass)

`similar_orders.sum { |o| o.runningTotal } / similar_orders.count` loaded all similar orders.
Fixed with `similar_orders.count` + `similar_orders.average('COALESCE(nett, 0)')`.

## MenuItemSearchIndexJob per-document SELECT + INSERT/UPDATE N+1 (MAJOR — fixed third pass)

Loop called `MenuItemSearchDocument.where(...).first` then `.update!` or `.create!` per document —
N SELECT + N INSERT/UPDATE per menu. Fixed with `upsert_all` (single round-trip, unique_by index).
Requires rubocop:disable Rails/SkipsModelValidations comment — validations not needed here.

## increment_metric read-then-write race condition (MINOR — fixed third pass)

`Rails.cache.read(key) + 1; Rails.cache.write(...)` is not atomic under concurrency and takes
2 round-trips. Fixed with `Rails.cache.increment(key, 1)` (atomic INCR on both Redis and Memcached).

## Menu + Menuitem cache invalidation inside transaction (MAJOR — fixed third pass)

`after_update :invalidate_menu_caches` / `after_update :invalidate_menuitem_caches` ran inside
the write transaction on the primary DB — blocking the commit while Memcached delete_matched
round-trips completed. Changed to `after_commit :..., on: %i[update destroy]` so invalidation
happens outside the transaction and never sees uncommitted data.

## restaurant.ordrs default scope incompatible with GROUP BY aggregates (KEY PATTERN)

`Restaurant#ordrs` is defined as `-> { reorder(orderedAt: :desc, id: :desc) }`.
Any time you GROUP BY on this relation, PostgreSQL raises:
  "column ordrs.orderedAt must appear in the GROUP BY clause or be used in an aggregate function"
Always call `.unscope(:order)` before `.group(...)` on any scope derived from `restaurant.ordrs`.

## Performance test suite location
- `test/performance/perf_audit_2026_test.rb` — first-pass audit tests (7 tests)
- `test/performance/perf_audit_2026b_test.rb` — second-pass audit tests (14 tests)
- `test/performance/perf_audit_2026c_test.rb` — third-pass audit tests (17 tests)
- `test/performance/perf_audit_2026d_test.rb` — fourth-pass audit tests (10 tests)
- All use `ActiveSupport::Notifications` to count SQL queries (no extra gems required)
- Base pattern: subscribe to `sql.active_record`, count/filter, assert upper bound

## KitchenBroadcastService#order_payload two-SUM → single pick() (MAJOR — fixed fourth pass)

`order.ordritems.sum(:quantity)` + `order.ordritems.sum('ordritemprice * quantity')` fired two
separate SQL SELECT SUM queries per broadcast. Fixed with a single `pick(SUM(quantity), SUM(ordritemprice * quantity))`.
Also: `order.restaurant.user` in `broadcast_new_order` triggered a lazy-load chain (restaurant via SQL,
then user via SQL). Fixed by using `order.fetch_restaurant` (IdentityCache) then `User.find_by(id: restaurant.user_id)`.

## invalidate_order_caches global wildcard → scoped (CRITICAL — fixed fourth pass, O2)

`delete_matched('restaurant_orders:*')` scanned keys for all tenants on every order update.
Fixed to `delete_matched("restaurant_orders:#{restaurant_id}:*")` when restaurant_id is known.
The method signature is now `invalidate_order_caches(order_id, restaurant_id: nil)`.
`CacheInvalidationJob` already received restaurant_id — now threads it through to the method.

## SmartMenuGeneratorJob tablesettings N+1 (MAJOR — fixed fourth pass)

`Tablesetting.where(restaurant_id:).each` was called INSIDE `Menu.find_each` (one SELECT per menu)
and again after the loop. Fixed by pre-loading `tablesettings.to_a` once before the menu loop.

## RegenerateMenuWebpJob flat_map N+1 (MAJOR — fixed fourth pass)

`menu.menusections.flat_map(&:menuitems)` loaded all sections then fired one SELECT per section
for menuitems. Fixed to `Menuitem.joins(:menusection).where(menusections: {menu_id:}).where.not(image_data: [nil,''])`.

## tablesettings_controller#show unbounded Menu.all (CRITICAL — fixed fourth pass)

`Menu.joins(:restaurant).all` loaded every menu across every restaurant.
Fixed to `Menu.where(restaurant_id: @restaurant.id, archived: false).includes(:restaurant).order(:sequence)`.

## userplans_controller per-restaurant active-menus COUNT N+1 (MAJOR — fixed fourth pass)

`current_user.restaurants.map { |r| r.restaurant_menus.joins(:menu)...count }.max` fired one COUNT
per restaurant. Fixed with GROUP BY: `RestaurantMenu.joins(:menu).where(restaurant_id:)...group(:restaurant_id).count.values.max`.

## AiMenuPolisherJob + ImportToMenu Allergyn Ruby .select (MINOR — fixed fourth pass)

Both called `Allergyn.where(restaurant:).select { |a| desired.include?(a.name.strip.downcase) }`.
Fixed to SQL: `.where('LOWER(TRIM(name)) IN (?)', desired)` — avoids loading all allergyns into Ruby.

## cache_warming_job in-memory status filter (MINOR — fixed fourth pass)

`restaurant.fetch_menus.select { |m| m.status == 'active' }` and
`restaurant.fetch_ordrs.select { |o| active_statuses.include?(o.status) }` loaded all
records via IdentityCache then discarded non-active ones in Ruby.
Fixed to `restaurant.menus.where(status: 'active').find_each` and
`Ordr.where(restaurant_id:, status: active_statuses).to_a`.

## HNSW index on menu_item_search_documents.embedding (MAJOR — fixed fourth pass, O1)

pgvector 0.8.0 installed in Postgres supports HNSW. Previous index was IVFFlat only.
Added migration 20260402090001 with `disable_ddl_transaction!` + `CREATE INDEX CONCURRENTLY`.
Parameters: m=16, ef_construction=64 (pgvector defaults, suitable for 384-dim embeddings).

## Ordr#ordritems reorder scope + GROUP BY — testing gotcha (KEY PATTERN)

`ordrs(:one).ordritems.pick(SUM(...))` fails with `PG::GroupingError` in tests because
`Ordr#ordritems` has `-> { reorder(id: :asc) }` which conflicts with the aggregation.
Workaround: use `Ordritem.unscoped.where(ordr_id: order.id).pick(...)` in tests.
