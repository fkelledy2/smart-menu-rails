---
name: Badge bg-* vs text-bg-* pattern
description: Codebase uses both old bg-* and new text-bg-* badge patterns — text-bg-* is the correct Bootstrap 5 pattern and is being migrated to
type: project
---

Bootstrap 5 introduced `text-bg-{color}` as the preferred badge/background-color helper. It auto-handles text contrast. The old pattern `bg-{color}` (with separate `text-dark` for light colours) is still scattered throughout but is being removed.

**Correct pattern:** `<span class="badge text-bg-success">` not `<span class="badge bg-success">`

**Exception — intentional:** `bg-success bg-opacity-75` (custom opacity) and `bg-*-subtle text-*` (Bootstrap 5.3 subtle variants) are intentional and should not be changed.

**Why:** Consistency, correct contrast handling in dark mode, Bootstrap 5 spec compliance.

**How to apply:** When reviewing or writing any badge in admin views, always use `text-bg-*`. The `env_badge_class` helper in `admin/cost_insights_helper.rb` was updated to return just the variant name (e.g. `'warning'`) and views use `text-bg-<%= env_badge_class(...) %>`.
