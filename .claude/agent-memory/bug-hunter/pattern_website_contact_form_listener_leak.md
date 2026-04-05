---
name: website_contact_form_controller listener leak via .bind(this)
description: connect() called addEventListener with this.handleSubmit.bind(this); disconnect() called removeEventListener with a fresh .bind(this) — different function references, listener never removed on Turbo navigation
type: project
---

`website_contact_form_controller.js` used `.bind(this)` inline in both `connect()` and `disconnect()`. Each call to `.bind()` creates a new function object, so the reference passed to `removeEventListener` never matches the one added in `addEventListener`. The listener accumulates on Turbo navigation.

**Fix applied:** Stored the bound reference as `this._handleSubmit` in `connect()`, used that stored reference in both `addEventListener` and `removeEventListener`, nulled it in `disconnect()`.

**Why:** Same root cause as `auto_save_controller` (pattern_auto_save_listener_leak). This pattern is a recurring mistake when adding native DOM event listeners in Stimulus controllers.

**How to apply:** Always store bound listener references as instance properties. Pattern: `this._fn = this.method.bind(this)` in connect, `removeEventListener(this._fn)` in disconnect.
