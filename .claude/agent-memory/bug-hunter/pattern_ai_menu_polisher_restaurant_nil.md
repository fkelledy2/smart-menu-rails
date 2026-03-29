---
name: AiMenuPolisherJob restaurant nil dereference
description: AiMenuPolisherJob discarded menu.restaurant result then called menu.restaurant.id later — NoMethodError if restaurant deleted
type: project
---

AiMenuPolisherJob line 13 called `menu.restaurant` but discarded the result. Line 139 then called `menu.restaurant.id` which (a) triggers an extra DB query and (b) raises NoMethodError if the restaurant association is nil (e.g. restaurant deleted after job was enqueued).

Fix: assign the result to a local variable `restaurant = menu.restaurant` and use `restaurant.id if restaurant` at the cache invalidation call.

**Why:** Line 13 was a leftover no-op call; a subsequent line in the same method assumed the restaurant was always present.

**How to apply:** Any job or service that accesses an AR association more than once should cache it in a local variable and nil-guard on use.
