---
name: Menu Optimization section_reorder completely non-functional
description: validate_and_sanitise_change_set drops section_reorder because it checks menuitem_ids but section_reorder uses menusection_id as target_id
type: project
---

`section_reorder` actions proposed by the LLM are silently dropped at two layers:

1. `validate_and_sanitise_change_set` (menu_optimization_workflow.rb ~491) builds `item_ids` from `menuitem_id` fields but `section_reorder` uses `target_id = menusection_id`. The filter `item_ids.include?(action['target_id'].to_i)` always fails for section IDs.

2. Even if an action survived, `apply_action` in `ApplyApprovedMenuChangesJob` fetches `menuitems` by `target_id` — for a section ID, this returns nil and the method silently returns.

**Why:** The LLM prompt (line 436) documents that `section_reorder` uses `target_id: menusection_id`, but the validation filter and apply logic both assume `target_id` is always a `menuitem_id`.

**How to apply:** When investigating any section_reorder approval bug reports, start here. The entire feature needs the validation filter to handle section IDs separately, and `apply_action` needs a separate section_reorder path that updates `Menusection#sequence`, not `Menuitem#sequence`.
