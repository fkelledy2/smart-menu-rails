---
name: Index additions from March 2026 performance audit
description: Indexes added in migration 20260329222214 and their rationale
type: project
---

## Migration: 20260329222214_add_performance_indexes.rb

All indexes use `if_not_exists: true` for safe re-runs.

| Table | Index | Rationale |
|-------|-------|-----------|
| restaurants | status | Frequently filtered (active/inactive/archived scopes) but only a partial index existed |
| ordrs | orderedAt | Used in revenue_summary GROUP BY and date-range analytics; no dedicated index existed |
| ordractions | [ordr_id, action] | orderedCount/orderedItems filter on both columns |
| menuitemlocales | menuitem_id, LOWER(locale) | resolve_localised_name has a case-insensitive fallback path |
| restaurantlocales | restaurant_id, LOWER(locale) | getLocale uses LOWER(locale) fallback |
| menuitems | [menusection_id, itemtype, status] WHERE archived=false | whiskey_ambassador_ready? queries on these three columns |
| ordritems | [ordr_id, menuitem_id] | cached_menu_performance subquery uses ordr_id IN (...) with menuitem_id filter |

## Migration: 20260402090001_add_hnsw_index_to_menu_item_search_documents.rb

| Table | Index | Rationale |
|-------|-------|-----------|
| menu_item_search_documents | HNSW (embedding vector_cosine_ops) m=16 ef_construction=64 | Better recall than IVFFlat; no pre-training required; pgvector 0.8.0 supports HNSW |

Uses `disable_ddl_transaction!` + `CREATE INDEX CONCURRENTLY IF NOT EXISTS`.
Previous IVFFlat index kept for now (planner picks cheapest; can be removed after benchmarking).

**Why:** These were identified as missing indexes on high-traffic query paths.
**How to apply:** When writing new queries filtering on these tables, the above indexes should cover common patterns.
