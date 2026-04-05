---
name: CRM set_lead missing halt after head :not_found
description: Admin::Crm::LeadsController#set_lead called head :not_found without return — action body continued with @lead nil (FIXED)
type: project
---

`head :not_found unless @lead` without `return` lets the action body continue executing against nil `@lead`, causing NoMethodError.

**Fix:** Use `head :not_found and return unless @lead`.

**Why:** `head` sends a response but doesn't halt Ruby execution. In a `before_action`, the filter chain halts only when `performed?` is true — which `head` does set, but the method itself continues to the `end` after calling `head`. Using `and return` exits the method immediately.

**How to apply:** Any `before_action` that calls `head :status_code` without `return` has this bug. Always use `and return` after `head` in before_actions.
