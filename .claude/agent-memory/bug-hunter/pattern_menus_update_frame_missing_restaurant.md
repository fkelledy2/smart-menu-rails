---
name: MenusController#update turbo-frame render missing restaurant/restaurant_menu/read_only locals
description: The successful update path for Turbo Frame requests renders section_frame_2025 with only menu and partial_name — restaurant, restaurant_menu and read_only are absent
type: project
---

In `app/controllers/menus_controller.rb` lines 298–299:
```ruby
render partial: 'menus/section_frame_2025',
       locals: { menu: @menu, partial_name: menu_section_partial_name(@current_section) }
```

The `_section_frame_2025` partial passes all locals to the section partial:
```erb
<%= render "menus/sections/#{partial_name}",
    menu: local_assigns[:menu],
    restaurant: local_assigns[:restaurant],      # nil
    restaurant_menu: local_assigns[:restaurant_menu],  # nil
    read_only: local_assigns[:read_only] %>        # nil
```

Every section partial begins with:
```erb
<% restaurant = local_assigns[:restaurant] || @restaurant || menu.restaurant %>
```

So `restaurant` falls back to `menu.restaurant` — this particular nil is tolerated. However `restaurant_menu` stays nil and `read_only` is `nil` (falsy, treated as false). These are acceptable fallbacks for the settings section, but any section that uses `restaurant_menu.present?` (like `_details_2025` availability widget at line 133) silently skips sections rather than crashing.

The same missing-locals pattern also applies to the failure path at line 311–313.

**Impact**: low-severity — no crash, but the availability override widget in the read-only details panel is hidden after a Turbo-frame menu update.

**Fix**: pass the full set of locals in both render calls:
```ruby
locals: {
  menu: @menu,
  partial_name: menu_section_partial_name(@current_section),
  restaurant: @restaurant || @menu.restaurant,
  restaurant_menu: @restaurant_menu,
  read_only: @read_only_menu_context,
}
```

**File**: `app/controllers/menus_controller.rb` lines 298–299 and 311–313
