---
name: Stimulus controllers must not hard-code user-facing strings
description: Pattern for keeping Stimulus controllers locale-agnostic via data-value attributes
type: feedback
---

Stimulus controllers must not contain hard-coded user-facing strings (e.g. "Updated just now", status labels). Instead:

1. Render the translated string server-side in the ERB partial and store it in a `data-*` attribute on a DOM element.
2. Read that attribute in the Stimulus controller via `element.dataset.*` or a Stimulus value (`static values = { statusLabels: Object }`).

**Established pattern (from `ordritem_tracking_controller.js`):**
- `data-ordritem-tracking-status-labels-value` — JSON map of `{ pending: "Received", preparing: "Preparing", ... }` populated by the partial via `t('smartmenus.ordritem_tracking.status_*')`.
- `data-updated-label` — the "Updated just now" string on each timestamp element, set server-side.

**Why:** The kitchen dashboard and customer-facing smart menu are used in 40+ locales. Hard-coded English in JS breaks those locales silently (no runtime error, just wrong language shown).

**How to apply:** Any time a Stimulus controller needs to display a string to the user, define a corresponding Stimulus value (or read a data attribute) and populate it from the ERB partial via `t()`.
