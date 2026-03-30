---
name: demo_booking_controller XSS via innerHTML error messages
description: demo_booking_controller.js #showErrors injected server-supplied error messages via innerHTML — stored XSS vector
type: project
---

`#showErrors` in `demo_booking_controller.js` used `innerHTML` to inject server-supplied error message strings. Error messages come from the server's JSON response (`data.errors`) which could contain HTML/JS if the server ever echoes user input in validation messages.

**Why:** Same root cause class as whiskey_ambassador and sommelier XSS — innerHTML with non-literal content is always risky regardless of source.

**How to apply:** Any Stimulus controller that builds HTML from fetch response data must use `textContent` / `createElement` + `appendChild`, never `innerHTML` with dynamic content. Fixed in place — `#showErrors` now creates `<div>` elements with `textContent`.
