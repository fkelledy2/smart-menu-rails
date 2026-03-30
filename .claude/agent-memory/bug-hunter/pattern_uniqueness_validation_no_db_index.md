---
name: uniqueness_validation_no_db_index
description: menuitem_tag_mappings and menuitem_ingredient_mappings had validates uniqueness without backing DB unique index — race condition allows duplicate mappings
type: feedback
---

`MenuitemTagMapping` validates `menuitem_id` uniqueness scoped to `tag_id`, and `MenuitemIngredientMapping` validates `menuitem_id` uniqueness scoped to `ingredient_id`. Neither had a backing unique DB index, meaning two concurrent requests could each pass the validation check and both write — creating duplicate join-table records.

**Why:** Rails uniqueness validation is not atomic; it issues a SELECT then INSERT, with a TOCTOU gap. Only a database-level unique constraint prevents duplicates under concurrent load.

**How to apply:** Migration `20260330180001` adds `CONCURRENT` unique indexes on both tables. Index names: `index_menuitem_tag_mappings_on_menuitem_id_and_tag_id` and `idx_menuitem_ingredient_mappings_unique` (shortened to stay under 63-char PG limit). (FIXED)
