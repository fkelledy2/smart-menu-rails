---
name: console.log statements left in production JS
description: Multiple Stimulus controllers had console.log statements left in production JavaScript
type: feedback
---

split_bill_controller.js, bottom_sheet_controller.js, sortable_controller.js, tab_bar_controller.js, order_notes_controller.js, auto_save_controller.js, ordering_controller.js, state_controller.js, and index.js all had `console.log` (and one `console.debug`) statements left in production JavaScript.

`index.js` had a large `console.log` at the bottom listing all registered controller names.

**Why:** These leak implementation details and clutter browser devtools. They were likely added during development and never removed.

**How to apply:** After every pass of Stimulus controller work, grep for `console\.log` and `console\.debug` in `app/javascript/controllers/` and remove any that are not deliberate production-facing error/warning logs.
