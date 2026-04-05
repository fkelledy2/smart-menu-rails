---
name: SearchMenuItems returns hidden items to customers
description: SearchMenuItems tool lacked hidden filter — 86'd items included in concierge recommendations (FIXED)
type: feedback
---

`Agents::Tools::SearchMenuItems` did not filter for `hidden: [false, nil]` items. Any item that had been 86'd (set `hidden: true`) would still be returned to customers via the customer concierge endpoint.

**Why:** The tool was added with only `menus: { archived: false }` scope and allergen exclusion, but never added the visibility guard that the rest of the app uses (`Menuitem.scope :visible`).

**How to apply:** Any new query on `Menuitem` for customer-facing use must include `.where(hidden: [false, nil])` or `.visible`. The `scope :visible` is defined in `app/models/menuitem.rb:140`.

Fixed in `app/services/agents/tools/search_menu_items.rb` by adding `.where(hidden: [false, nil])` immediately after the archived filter.
