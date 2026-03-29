---
name: Sommelier controller tag XSS
description: sommelier_controller.js injects rec.tags values into innerHTML without escapeHtml — stored XSS, same class as whiskey_ambassador_controller
type: project
---

`sommelier_controller.js` lines 277 and 333:
```js
.map((t) => `<span class="sommelier-tag">${t.replace(/_/g, ' ')}</span>`)
```

`rec.tags` comes from the AI recommendation JSON response, seeded from staff-editable menu item fields. The `.replace(/_/g, ' ')` call does not HTML-escape. The controller already has an `escapeHtml()` method at line 33 but it is not applied to tags.

**Why:** Same class of bug as `whiskey_ambassador_controller.js` (already fixed). Tags are treated as safe display strings but they originate from user-controlled data.

**How to apply:** Fix is `this.escapeHtml(t.replace(/_/g, ' '))`. Check any other innerHTML injections in AI recommendation controllers for the same pattern.
