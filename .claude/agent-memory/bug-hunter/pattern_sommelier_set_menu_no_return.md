---
name: SommelierController#set_menu missing return
description: set_menu before_action rendered not_found but did not return — action body ran against nil @menu
type: feedback
---

`SommelierController#set_menu` (line 146) rendered `json: { error: 'No menu' }` but did not `return`. All action methods (`recommend`, `recommend_wine`, `pairings`, etc.) called `@menu.menuitems` / `@menu.whiskey_flights` on nil, crashing with NoMethodError.

**Fix:** Added explicit `return if @menu` after nil-guard to halt the before_action chain.

**Why:** Rails before_action halts only when `render`/`redirect_to` is called AND the response is committed. When the `unless` guard uses `render ... unless @menu` without a prior `return`, Ruby doesn't halt execution of the caller — the action body continues even though the response has already been set, causing a double-render or NoMethodError crash.

**How to apply:** Every before_action that conditionally renders a not_found must explicitly `return` after the render call.
