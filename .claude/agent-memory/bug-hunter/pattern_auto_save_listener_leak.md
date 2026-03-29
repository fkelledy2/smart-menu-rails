---
name: auto_save_listener_leak
description: auto_save_controller.js adds input/change listeners with inline .bind(this) in connect() — references not stored, so disconnect() cannot remove them, causing listener accumulation on Turbo navigation
type: project
---

`app/javascript/controllers/auto_save_controller.js` lines 28-29:
```js
el.addEventListener('input', this.handleInput.bind(this));
el.addEventListener('change', this.handleChange.bind(this));
```

`.bind(this)` creates a new function object on each call. The reference is not stored, so `disconnect()` cannot call `removeEventListener` with the matching function. Every Turbo navigation that reconnects the form accumulates more listeners on the same input elements.

The `document` keydown listener IS properly stored (`this._handleKeyDown`) and removed in `disconnect()`.

**Why:** Oversight in original implementation — only the document listener was given proper lifecycle management.
**How to apply:** Fix by storing bound handlers as instance properties in `connect()` before adding them, then removing in `disconnect()` by iterating stored elements. Or use Stimulus `data-action` directives instead of programmatic `addEventListener`.
