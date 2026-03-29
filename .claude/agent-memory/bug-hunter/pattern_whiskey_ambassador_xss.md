---
name: whiskey_ambassador_xss
description: whiskey_ambassador_controller.js interpolates server-provided strings (rec.name, staff_tasting_note, flight.title, pick.name) directly into innerHTML without HTML escaping — stored XSS via staff-editable menu fields
type: project
---

`app/javascript/controllers/whiskey_ambassador_controller.js` injects data from the sommelier API into `innerHTML` on multiple lines (315, 322, 329, 360, 404 etc.):
```js
<h4 class="wa-card-title">${rec.name}</h4>
${rec.staff_tasting_note ? `<p class="wa-tasting-note">"${rec.staff_tasting_note}"</p>` : ''}
```

`rec.name` is `item.name` and `staff_tasting_note` is from `sommelier_parsed_fields` — both are staff-editable text stored in the database. A staff member who can edit menu items can inject arbitrary HTML/JS that executes in any customer's browser viewing their whiskey recommendations.

**Why:** innerHTML was used for convenience rather than textContent/DOM methods. No server-side output encoding is applied to JSON API responses because that is typically the client's responsibility.
**How to apply:** Add an `escapeHtml()` helper (already present in `inline_edit_controller.js`) and wrap all interpolated user-controlled fields. Fields like `menuitem_id`, `score`, `price` (numeric) are safe; `name`, `distillery`, `staff_tasting_note`, `why_text`, `flight.title`, `flight.narrative`, `item.note` all need escaping.
