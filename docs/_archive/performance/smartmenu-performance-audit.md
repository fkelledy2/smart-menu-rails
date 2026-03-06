# Smartmenu Customer View — Performance Audit

**Date:** 2026-02-16
**Scope:** `/smartmenus/:slug` — full page load + WebSocket partial updates

---

## Executive Summary

The smartmenu customer view has **7 critical performance bottlenecks** that compound on mobile devices. The most impactful are:

1. **`@restaurant.reload` on every request** — destroys eager-loaded associations, adding 3-5 extra queries
2. **Missing composite DB index** on `ordrs(menu_id, tablesetting_id, status)` — the open-order lookup does a sequential scan
3. **Redundant `Menu.find`** — the menu is loaded twice with different includes
4. **Full HTML partial re-rendering on every order item change** — `broadcast_partials` renders 8+ partials server-side on each add/remove
5. **Unnecessary JS/CSS on customer pages** — Stripe.js loaded synchronously, Font Awesome 6 full library, Google Maps loader, admin-only CSS
6. **No PG vacuum/maintenance schedule** — hot tables (ordrs, ordritems, ordrparticipants) accumulate dead tuples
7. **ActionCable slug-based subscription** without order-scoped filtering

---

## A) Rendering Performance — With and Without Images

### Issues Found

| # | Issue | Impact | Fix |
|---|-------|--------|-----|
| A1 | `@restaurant.reload` in `load_restaurant_locales` (line 242) | **HIGH** — Forces full DB reload of restaurant + all associations, undoing eager loading from `set_smartmenu`. Adds 3-5 queries per request. | Remove `.reload`, filter restaurantlocales from already-loaded association |
| A2 | `load_menu_associations_for_show` fires a second `Menu.find(@menu.id)` | **HIGH** — Discards the menu loaded in `set_smartmenu` and fires a completely separate query with different includes. | Merge includes into `set_smartmenu` or use `.preload` on existing object |
| A3 | `AlcoholOrderEvent.exists?(ordr_id:)` on every show | **LOW** — Extra DB hit, but uses index. | Cache on the order or check only when tablesetting present |
| A4 | `Menuparticipant.find_or_create_by` + conditional `.update` | **MEDIUM** — Two DB writes on every page load | Combine into single upsert, skip update when unchanged |
| A5 | Fragment cache key includes `@openOrder` | **MEDIUM** — Menu content cache is busted on every order state change. The menu content itself doesn't change with order state. | Remove order from menu content cache key (action bar is already outside cache in the horizontal partial) |
| A6 | `broadcast_partials` renders 8+ full HTML partials on every order item change | **CRITICAL** — Each add/remove triggers server-side rendering of menuContentCustomer, menuContentStaff, orderCustomer, orderStaff, modals, context, and 2 table selectors. Each partial is compressed and broadcast. This blocks the worker for 200-500ms. | Switch to JSON-only state broadcasts (client already handles `state:update` events) |

### Fragment Caching (Current State)

| Fragment | Cache Key | TTL | Status |
|----------|-----------|-----|--------|
| Menu header | `[@smartmenu, @menu, @restaurant, @header_cache_buster, ...]` | 1h | ✅ Good |
| Menu content | `[@smartmenu, @menu, @active_menu_version, allergyns_updated_at, locale, view_type]` | 30min | ⚠️ Works but could be longer since menu changes are rare |
| Menu item (horizontal) | `["menuitem-horizontal", menuitem, locale, updated_at]` | default | ✅ Good — per-item caching |
| Allergens | `[allergyn.cache_key_with_version, locale]` | default | ✅ Good |

### Image Rendering (Already Optimised)

- `picture_tag_with_webp` generates `<picture>` with WebP srcset ✅
- `card_webp` (150px, q70) for mobile card view ✅
- `lazy` loading on all below-fold images ✅
- `image_sizes` uses mobile-first breakpoints ✅
- Modal images use `optimised_modal_url` (WebP medium) ✅

---

## B) Page Responsiveness

### JS/CSS Payload Issues

| # | Issue | Impact | Fix |
|---|-------|--------|-----|
| B1 | **Font Awesome 6 full CSS** loaded on all pages (~90KB gzipped) | **HIGH** — Customer pages only use Bootstrap Icons (`bi-*`), never Font Awesome | Conditionally load only on admin pages |
| B2 | **Google Maps API loader** defined in `<head>` for all pages | **MEDIUM** — 2KB inline JS + potential network request on customer pages that never use maps | Move to admin-only partial |
| B3 | **Stripe.js loaded synchronously** in smartmenu layout | **HIGH** — `<script src="https://js.stripe.com/v3">` is render-blocking. Only needed for payment flow. | Add `async` or `defer` attribute |
| B4 | **QR Code Styling library** loaded on all pages | **LOW** — async but still a network request | Move to payment-only partial |
| B5 | **~200 lines of inline CSS** in `_head.html.erb` | **MEDIUM** — Tabulator styles, admin button overrides loaded on customer pages | Extract to admin-only stylesheet or scope to controller |

### Recommended Head Optimisations

```erb
<%# In shared/_head.html.erb — conditional loading %>
<% unless controller_name == 'smartmenus' && action_name == 'show' && !current_user %>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta2/css/all.min.css" ...>
<% end %>
```

---

## C) Full Page Refresh vs. WebSocket Partial Updates

### Current Architecture

1. **Full page load**: Controller eager-loads all data → renders HTML with fragment caching
2. **WebSocket updates**: `broadcast_partials` re-renders 8+ full HTML partials server-side → compresses → broadcasts via ActionCable
3. **Client**: `ordr_channel.js` receives JSON state (`state:update` event) — the HTML partial path is effectively dead code since `USE_JSON_STATE = true`

### Key Finding

The `broadcast_partials` method in `ordritems_controller.rb` (lines 345-521) renders full HTML partials and compresses them, but the client-side `received(data)` handler (line 625-636) only processes JSON state updates via `document.dispatchEvent(new CustomEvent('state:update', ...))`. **The compressed HTML partials are being generated but never used by the client**.

### Recommendation

Remove the HTML partial rendering from `broadcast_partials`. Send only the JSON state payload (which the client already consumes). This would:
- Reduce broadcast latency from ~200-500ms to ~5-10ms
- Free up worker threads
- Eliminate N+1 queries in the broadcast path

---

## D) Cross-Order Pollination

### Current Channel Design

```ruby
# OrdrChannel subscribes by:
stream_from "ordr_#{identifier}_channel"
# Where identifier is either order_id or smartmenu slug
```

### Risk Assessment

| Scenario | Channel | Isolation | Risk |
|----------|---------|-----------|------|
| Same table, same order | `ordr_{slug}_channel` | ✅ Correct — all participants share state | None |
| Different tables | Different slugs | ✅ Isolated | None |
| General smartmenu (`tablesetting_id: nil`) | `ordr_{slug}_channel` | ⚠️ All customers on general link share channel | **LOW** — General links don't have orders/tablesettings, so no order data flows |
| Order-specific broadcast | `ordr_{order_id}_channel` | ✅ Scoped to order | None |

### Dual Broadcasting Pattern

Some controllers broadcast to BOTH channels:
```ruby
ActionCable.server.broadcast("ordr_#{ordr.id}_channel", { state: payload })
ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", { state: payload })
```

This is correct — it ensures both slug-subscribed (pre-order) and order-subscribed (post-order) clients receive updates. **No cross-order pollination risk identified**, but the client should verify `order.id` matches before applying state to be defensive.

---

## E) Database Indexes

### Missing Indexes (Critical)

| # | Table | Columns | Query | Priority |
|---|-------|---------|-------|----------|
| E1 | `ordrs` | `(menu_id, tablesetting_id, status)` | `load_open_order_and_participant` — filtered on menu_id + tablesetting_id + restaurant_id + status | **CRITICAL** |
| E2 | `menuparticipants` | `(sessionid, smartmenu_id)` unique | `find_or_create_by(sessionid:)` then checks smartmenu | **HIGH** |
| E3 | `alcohol_order_events` | `(ordr_id, age_check_acknowledged)` | `exists?(ordr_id:, age_check_acknowledged: false)` | **LOW** |

### Existing Indexes (Adequate)

- `ordrs`: Good coverage on `(restaurant_id, status)`, `(tablesetting_id, status)`, `menu_id` — but no composite covering the 3-column WHERE clause
- `menuitems`: Excellent coverage with `(menusection_id, status, sequence)` partial index
- `ordritems`: Good with `(ordr_id, status)`, `(ordr_id, created_at)`
- `smartmenus`: Good with `slug` unique index and restaurant composites

---

## F) PG Maintenance

### Current State

No scheduled vacuum or index maintenance found in the codebase.

### Recommended Schedule

| Task | Frequency | Target Tables |
|------|-----------|---------------|
| `VACUUM ANALYZE` | Daily (off-peak) | ordrs, ordritems, ordrparticipants, ordractions, menuparticipants |
| Index bloat check | Weekly | All tables with high write volume |
| `pg_stat_statements` review | Weekly | Identify slow queries |
| `REINDEX CONCURRENTLY` | Monthly | Tables with >30% index bloat |

### Heroku-Specific Notes

Heroku Postgres runs autovacuum, but with conservative settings. For tables with high write churn (ordrs, ordritems), consider:
- `ALTER TABLE ordrs SET (autovacuum_vacuum_scale_factor = 0.05)` (default is 0.2)
- `ALTER TABLE ordritems SET (autovacuum_vacuum_scale_factor = 0.05)`

---

## Architectural Recommendations

### Short-Term (Implement Now)

1. **Remove `@restaurant.reload`** — Use already-loaded associations
2. **Merge eager loading** — Single `set_smartmenu` query with all needed includes
3. **Add missing composite index** on `ordrs(menu_id, tablesetting_id, status)`
4. **Add `defer` to Stripe.js** — Non-blocking script load
5. **Conditionally load Font Awesome** — Only on admin pages

### Medium-Term (Next Sprint)

6. **Eliminate HTML partial broadcasting** — The client uses JSON state only. Remove the 8-partial render from `broadcast_partials` and send only `SmartmenuState.for_context` JSON.
7. **Add PG maintenance rake task** with Heroku Scheduler integration
8. **Split `_head.html.erb`** into admin vs. customer variants

### Long-Term (Architectural)

9. **Turbo Frames for order UI** — Instead of full page state management via JS, use Turbo Frames for the order panel, cart, and modals. This would eliminate the custom JS state machine and use Rails' built-in partial update mechanism.
10. **Edge caching for menu content** — Since menu content is locale-dependent but order-independent, it could be served from CDN edge with proper `Vary` headers. The order UI would load separately via Turbo Frame or XHR.
11. **Consider read replicas** — The `load_open_order_and_participant` query and `eager_load_open_order` could read from a replica to reduce primary DB load during peak hours.
