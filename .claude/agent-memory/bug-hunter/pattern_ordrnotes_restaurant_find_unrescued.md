---
name: OrdrnotesController#set_restaurant unrescued RecordNotFound
description: OrdrnotesController set_restaurant used Restaurant.find without rescue — unhandled 500 on bad restaurant_id (FIXED)
type: project
---

`OrdrnotesController#set_restaurant` called `Restaurant.find(params[:restaurant_id])` with no rescue clause. An invalid or deleted restaurant_id produces a 500 `ActiveRecord::RecordNotFound` rather than a clean 404 or redirect.

**Why:** Same root cause class as whiskey_imports, allergyns, taxes, tablesettings controllers (already fixed). The controller also has inline ownership authorization logic rather than using Pundit policy, which means the rescue must cover both the find and the auth check.

**How to apply:** Every `Model.find` in a `before_action` set_* method needs a `rescue ActiveRecord::RecordNotFound` that renders or redirects gracefully. Fixed with `rescue ActiveRecord::RecordNotFound` handling both HTML and JSON formats.
