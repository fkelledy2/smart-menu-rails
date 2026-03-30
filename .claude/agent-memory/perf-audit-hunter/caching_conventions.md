---
name: Caching conventions and IdentityCache models
description: Which models use IdentityCache, how AdvancedCacheService works, counter caches
type: project
---

## IdentityCache models (Memcached)
- `Ordr` — cache_index on :id, :restaurant_id, :tablesetting_id, :menu_id, :employee_id
- `Ordritem` — cache_index on :id, :ordr_id, :menuitem_id
- `Menuitem` — cache_index on :id, :menusection_id, :status, composite :menusection_id+:status
- `Restaurant` — cache_index on :id, :user_id
- Cache invalidation is done via background job `CacheInvalidationJob` (not inline callbacks)

## AdvancedCacheService (app/services/advanced_cache_service.rb)
- Wraps `Rails.cache.fetch` with Memcached (Dalli) as the store
- Key pattern: `"resource_type:id:qualifier"` (e.g. `"menu_full:42:en:false"`)
- TTLs: menu_full=30min, restaurant_dashboard=15min, restaurant_orders=10min, order_full=30min
- Cache invalidation uses `delete_matched` patterns — be careful, this is O(n) on Memcached
- `AdvancedCacheServiceV2` wraps V1 and returns ActiveRecord model instances alongside cached data

## Counter caches (avoid COUNT queries)
- `Restaurant` has `menus_count`, `employees_count`, `ordrs_count`, `tablesettings_count`, `ocr_menu_imports_count`
- `Ordr` has `ordritems_count`, `ordrparticipants_count`
- `Menu` has `menuitems_count`, `menusections_count`
- `Menuitem` has `ordritems_count`
- Always read these columns directly rather than calling `.count` on the association

## Materialized views
- `dw_orders_mv` — refreshed every 1 hour (medium priority)
- `restaurant_analytics_mv` — refreshed every 15 minutes (high priority)
- `menu_performance_mv` — refreshed every 30 minutes (medium priority)
- `system_analytics_mv` — refreshed every 1 hour (low priority)
- All views use CONCURRENT refresh. DwOrdersMv model is readonly.
- These are intended for the read replica (15s timeout), not the primary (5s timeout).

## Tax calculation caching
- `OrdrsController#calculate_order_totals` caches tax data in Rails.cache per restaurant per day:
  `"restaurant_taxes:#{restaurant_id}:#{Date.current}"` expires_in: 1.hour
- Returns plucked `[taxpercentage, taxtype]` pairs — no ActiveRecord objects

**Why:** Caching architecture is important to understand to avoid double-caching or cache-busting loops.
**How to apply:** When adding new computed data, check whether a counter_cache already exists before adding a query.
