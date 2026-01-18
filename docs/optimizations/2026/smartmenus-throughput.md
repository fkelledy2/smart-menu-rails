# /smartmenus Throughput Optimization (2026)

## Context

This write-up revisits throughput optimization opportunities for the public-facing `GET /smartmenus/:slug` experience, with particular focus on:

- SQL/query efficiency
- caching
- indexing

Key constraints/assumptions:

- Clients (browsers) connect via ActionCable and receive order updates as JSON payloads.
- Clients apply partial re-rendering based on received order state.
- Typical menu size is ~10–12 sections with ~10–15 items per section (~120–180 items).
- Prod DB is Heroku Postgres.

## Current request flow (high-level)

### Primary entry point

- `SmartmenusController#show`
  - Loads `@smartmenu`, `@restaurant`, `@menu`, `@tablesetting` in `set_smartmenu`.
  - Calls `load_menu_associations_for_show` (heavy eager loading).
  - Loads allergens (`@menu.allergyns` with fallback to `@restaurant.allergyns`).
  - Finds/loads open order (`Ordr`) for table/menu, then eager loads order items and related menuitem locales.
  - Creates/updates `Menuparticipant` and `Ordrparticipant` rows per session.
  - Renders HTML (with fragment caching) or JSON payload via `SmartmenuState.for_context`.

### Real-time updates

- After order mutations, controllers broadcast `SmartmenuState.for_context(...)` over ActionCable.
  - This means payload generation performance affects throughput under load.

## Primary bottlenecks identified

### 1) View-layer queries defeat controller eager loading

Even though `load_menu_associations_for_show` eagerly loads a large graph, the smartmenu templates still issue queries per section and per item.

Examples:

- Per section:
  - `menusection.menuitems.where(status: 'active').order(:sequence)`
  - `Menuitem.where(menusection_id: ..., tasting_carrier: true).first`

- Per item (staff view):
  - `menuitem.menuitem_size_mappings.count` (count query)

Impact:

- For ~12 sections, the above patterns can add dozens of queries per page render.

### 2) Localization methods cause a large hidden N+1

`Menuitem#localised_name/description`, `Menusection#localised_name/description`, and `Menu#localised_name/description` currently query locale tables using:

- `...where('LOWER(locale) = ?', ...)`

Even if locale associations are preloaded (`menuitemlocales`, `menusectionlocales`, `menulocales`), these methods bypass preloaded data and hit DB.

Impact:

- With ~120–180 menu items plus section tabs, this can become hundreds of queries per page view.
- It also makes the ActionCable state payload more expensive (order items call `menuitem.localised_name(locale)`).

### 3) Fragment cache keys couple menu HTML to order updates

Menu content caching currently includes order timestamps (e.g. `@openOrder&.updated_at`).

Given websockets handle order-state UI updates, coupling menu HTML to order changes unnecessarily invalidates large caches.

## Recommendations

### A) SQL/query optimizations (highest ROI)

#### A1) Move all query logic out of the templates

- Stop calling `.where`, `.order`, `.count` in ERB on `menuitems`.
- Prepare prefiltered structures in the controller (or a dedicated presenter/service), e.g.:
  - `active_items_by_section_id`
  - `tasting_carrier_by_section_id`
  - `has_sizes_by_menuitem_id`

This should make “menu render queries” closer to O(1) rather than O(sections + items).

#### A2) Refactor localization to use preloaded associations

- If `menuitem.menuitemlocales` is loaded, search that in-memory collection.
- Same for `menusection.menusectionlocales` and `menu.menulocales`.

Also:

- Stop using `LOWER(locale)` in SQL.
- Normalize stored locale to lowercase at write time and query with `where(locale: locale.downcase)`.

This improves:

- initial menu render
- section tab render
- `SmartmenuState` payload generation (broadcast frequency)

#### A3) Reduce `load_menu_associations_for_show` preload breadth

It currently loads ingredients and mapping tables for all menu items. If these are not needed for smartmenu rendering, they should not be loaded.

Recommended approach:

- Create “smartmenu render preload” scopes tuned for customer/staff views.
- Only preload associations actually referenced in templates:
  - sections + items
  - locales
  - allergens + size mappings

### B) Caching (aligned with websocket delivery)

#### B1) Decouple menu HTML cache keys from order changes

Since order state updates arrive via websockets:

- Menu HTML fragments should depend on menu versioning signals (e.g., `@menu.updated_at`, locale, view type).
- Do not include `@openOrder.updated_at` in menu cache keys.

This prevents large menu fragment invalidation when orders change.

#### B2) Consider a short-lived cache for `SmartmenuState.for_context`

Under heavy service activity, rapid sequential broadcasts can compute identical payloads multiple times.

A safe starting point:

- cache key: `order_id + order.updated_at + locale + participant_id`
- TTL: 5–15 seconds

#### B3) Replace per-request “max(updated_at)” cache busters with touch propagation

The show action computes header cache busters via:

- `Smartmenu.maximum(:updated_at)`
- `Tablesetting.maximum(:updated_at)`

Consider `touch: true` propagation so you can use a single stable timestamp (e.g. `@restaurant.updated_at` or `@menu.updated_at`) as a cache version.

### C) Indexing

#### C1) `smartmenus.slug` uniqueness

Current usage:

- `Smartmenu.where(slug: params[:id]).first`

Recommendation:

- If slugs are intended globally unique, add a **unique** index on `smartmenus.slug`.
- If slugs are only unique per restaurant, enforce uniqueness on `(restaurant_id, slug)` and adjust lookup accordingly.

#### C2) Participant lookups (`find_or_create_by`) should be backed by composite indexes

High-frequency patterns:

- `Menuparticipant.find_or_create_by(sessionid: ...)`
- `Ordrparticipant.find_or_create_by!(ordr_id, role, sessionid, employee_id...)`

Recommended indexes:

- `menuparticipants(sessionid)` (optionally unique)
- `ordrparticipants(ordr_id, role, sessionid)` (unique for customer)
- `ordrparticipants(ordr_id, role, employee_id)` (staff)

These reduce contention and speed up participant creation under load.

## Heroku Postgres: verifying `pg_stat_statements`

### Check extension + preload libs

Use Heroku CLI:

- `heroku pg:psql -a <app-name>`

Then:

```sql
SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
SHOW shared_preload_libraries;
```

### Top queries by total time

```sql
SELECT
  calls,
  total_exec_time,
  mean_exec_time,
  rows,
  query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 50;
```

### Narrow to smartmenu-related tables

```sql
SELECT
  calls,
  total_exec_time,
  mean_exec_time,
  rows,
  query
FROM pg_stat_statements
WHERE
  query ILIKE '%smartmenus%' OR
  query ILIKE '%menus%' OR
  query ILIKE '%menusections%' OR
  query ILIKE '%menuitems%' OR
  query ILIKE '%menuitemlocales%' OR
  query ILIKE '%menusectionlocales%' OR
  query ILIKE '%menulocales%' OR
  query ILIKE '%ordrs%' OR
  query ILIKE '%ordritems%' OR
  query ILIKE '%ordrparticipants%'
ORDER BY total_exec_time DESC
LIMIT 100;
```

## Production evidence: `heroku pg:outliers`

`heroku pg:outliers` surfaced mostly **system catalog / driver introspection** queries (e.g., `pg_attribute`, `pg_type`, `pg_index`). These often come from tooling/ORM metadata lookups and are typically not the throughput bottleneck for `/smartmenus`.

The actionable application-level outlier observed was:

```sql
SELECT COUNT(*)
FROM "allergyns"
INNER JOIN "menuitem_allergyn_mappings"
  ON "allergyns"."id" = "menuitem_allergyn_mappings"."allergyn_id"
WHERE "menuitem_allergyn_mappings"."menuitem_id" = $1
```

This query indicates a per-menuitem `COUNT(*)` call against `mi.allergyns`.

### Root cause in code

- `app/views/smartmenus/_showMenuitemHorizontalActionBar.erb` used `mi.allergyns.count`.
- `app/views/smartmenus/_showMenuitemStaff.erb` used `menuitem.menuitem_size_mappings.count`.

Both patterns can trigger a SQL `COUNT(*)` per rendered menu item.

### Fix applied

- Replace `association.count` with `association.size` (uses preloaded association when available, otherwise may still query).
- Replace `association.count > 0` with `association.any?` (translates to an efficient `EXISTS` query if not loaded).

Files updated:

- `app/views/smartmenus/_showMenuitemHorizontalActionBar.erb`
- `app/views/smartmenus/_showMenuitemStaff.erb`

### Expected impact

- Reduced query volume during menu renders (especially customer views where every item renders an action bar).
- Removes a classic N+1 `COUNT(*)` pattern from the hot path.

## Prioritized execution plan

### Quick wins (highest impact, low risk)

- Refactor localization helpers to use preloaded associations.
- Remove view-level `.where/.order/.count` calls and compute these once server-side.
- Decouple menu fragment cache keys from `@openOrder.updated_at`.

### Medium effort

- Reduce preload breadth in `load_menu_associations_for_show`.
- Add composite indexes for participant lookup patterns.

### Longer-term

- Treat menu render data as a “cached artifact” keyed by a single menu cache version.
- Add instrumentation around `SmartmenuState.for_context` to measure payload build time and frequency.

## Success metrics

- **Initial menu render:** significant reduction in query count and total DB time.
- **Broadcast payloads:** stable/low CPU + no DB query spikes during service.
- **Cache hit rate:** high hit rate for menu fragments independent of order state.
- **P95 latency:** improved P95 for `GET /smartmenus/:slug`.
