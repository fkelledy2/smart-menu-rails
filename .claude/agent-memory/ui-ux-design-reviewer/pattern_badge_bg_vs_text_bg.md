---
name: Badge bg-* vs text-bg-* pattern
description: Codebase uses both old bg-* and new text-bg-* badge patterns — text-bg-* is the correct Bootstrap 5 pattern and is being migrated to
type: project
---

Bootstrap 5 introduced `text-bg-{color}` as the preferred badge/background-color helper. It auto-handles text contrast. The old pattern `bg-{color}` (with separate `text-dark` for light colours) is still scattered throughout but is being removed.

**Correct pattern:** `<span class="badge text-bg-success">` not `<span class="badge bg-success">`

**Exception — intentional:** `bg-*-subtle text-*` on non-badge elements (e.g. card backgrounds in `admin/metrics`) is acceptable. The `bg-primary-subtle text-primary` pattern on `.menu-origin-badge` in `_menus_2025.html.erb` is an intentional visual distinction, not a status badge.

**April 2026 sweep status (pass 2 - 2026-04-04):** Further fixed in: wait_times/(show, _estimates, _queue_list), receipt_deliveries/_send_receipt_success, profit_margin_targets/index, kitchen_dashboard/_station_ticket_card, profit_margins/(index, report, inventory_alerts), restaurants/sections/_profitability_margins_2025, menus/sections/_profitability_2025, ordrnotes/(_note_card, _order_notes_section), ordrs/_split_bill_status, bar_dashboard/_station_ticket_card, floorplans/_table_tile, shared/_analytics_dashboard, restaurants/agent_workbench/_status_badge.

**Why:** Consistency, correct contrast handling in dark mode, Bootstrap 5 spec compliance.

**How to apply:** When reviewing or writing any badge in admin views, always use `text-bg-*`. The `env_badge_class` helper in `admin/cost_insights_helper.rb` was updated to return just the variant name (e.g. `'warning'`) and views use `text-bg-<%= env_badge_class(...) %>`.
