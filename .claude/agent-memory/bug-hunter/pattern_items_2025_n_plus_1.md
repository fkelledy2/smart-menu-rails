---
name: _items_2025 and _sections_2025 partials have N+1 queries
description: _items_2025 fires one DB query per section for menuitems; _sections_2025 fires one COUNT per section
type: feedback
---

`app/views/menus/sections/_items_2025.html.erb` line 108-109:
```erb
<% menu.menusections.order(:sequence).each do |section| %>
  <% section_items = section.menuitems.where(archived: [false, nil]).where.not(status: :archived).order(:sequence) %>
```
This fires one SQL query per section. With 10 sections, 11 queries total. Also line 110 calls `section_items.any?` and line 119 calls `section_items.count` — two more queries per section.

`app/views/menus/sections/_sections_2025.html.erb` line 133:
```erb
<%= section.menuitems.count %>
```
Called inside `sections_for_menu.each` — one COUNT(*) per section.

**Why:** These partials are rendered on the menu edit page hot path. As menus grow, performance degrades linearly with section count.

**How to apply:** Preload `menuitems` in the controller or at the top of the partial, then group_by section_id. Use `menu.menusections.includes(:menuitems).order(:sequence)` and filter in Ruby, or use a single query keyed by section_id.
