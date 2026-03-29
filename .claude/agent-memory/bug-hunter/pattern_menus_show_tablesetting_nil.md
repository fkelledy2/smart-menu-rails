---
name: MenusController#show NoMethodError on nil tablesetting
description: show uses find_by for tablesetting then immediately calls .restaurant_id on it without a nil guard
type: project
---

In `app/controllers/menus_controller.rb` lines 101–107:
```ruby
@tablesetting = Tablesetting.find_by(id: params[:id])
@openOrder = Ordr.where(..., restaurant_id: @tablesetting.restaurant_id, ...)
```

`find_by` returns `nil` if the tablesetting has been deleted. Calling `.restaurant_id` on nil raises `NoMethodError` before any nil guard is applied.

The nil guard (`return unless @openOrder`) only comes at line 108 — after the crash has already happened.

**Fix**: add a nil guard immediately after the `find_by`:
```ruby
@tablesetting = Tablesetting.find_by(id: params[:id])
return unless @tablesetting
```

**File**: `app/controllers/menus_controller.rb` lines 101–103
