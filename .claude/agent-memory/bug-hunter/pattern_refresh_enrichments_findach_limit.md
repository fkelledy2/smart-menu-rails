---
name: RefreshEnrichmentsJob find_each ignores limit + stale.count re-queries
description: find_each silently drops .limit; stale.count fires a second query after processing giving wrong denominator
type: project
---

Two bugs in `Menu::RefreshEnrichmentsJob`:

1. `stale.find_each` — Rails `find_each` internally overrides `LIMIT` and `ORDER` for batch loading, so the `.limit(batch_size)` on the relation is silently ignored. All stale enrichments are processed, not just `batch_size`.

2. `stale.count` in the log line at the end of `perform` executes a fresh `COUNT(*)` query after all records have been processed. Because `ensure_product_enrichment!` creates new enrichments with future `expires_at` values, records just refreshed no longer match the `expires_at < now` condition — the denominator is lower than the actual batch size. Fixed by plucking IDs up-front and using `total = stale_ids.size`.

**How to apply:** When a batch size cap is needed with `find_each`, always pluck the IDs first (with `.limit`), then iterate. Never call `.count` on a live relation in the log line after records have been mutated — capture the total before processing.
