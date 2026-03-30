---
name: ordrnotes_find_unguarded
description: OrdrnotesController#set_order and #set_ordrnote used .find without rescue — 500 on bad ordr_id or note id
type: feedback
---

OrdrnotesController `set_order` called `@restaurant.ordrs.find(params[:ordr_id])` and `set_ordrnote` called `@order.ordrnotes.find(params[:id])` without `rescue ActiveRecord::RecordNotFound`. Both raised unhandled 500s on invalid IDs.

**Why:** Systematic sweep of all `.find` without rescue in controllers; this one was missed.

**How to apply:** Both `set_order` and `set_ordrnote` now have `rescue ActiveRecord::RecordNotFound` that redirects HTML and returns 404 JSON. (FIXED)
