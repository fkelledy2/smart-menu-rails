---
name: menu_import_controller.js keydown listener leak and uncleared setInterval
description: keydown .bind(this) in connect/disconnect creates mismatched refs so listener leaks; startPolish setInterval handle not stored and never cleared
type: project
---

Two bugs in `app/javascript/controllers/menu_import_controller.js`:

1. Lines 67/78 — keydown listener:
```js
// connect():
document.addEventListener('keydown', this.handleKeyDown.bind(this));
// disconnect():
document.removeEventListener('keydown', this.handleKeyDown.bind(this));
```
`.bind(this)` creates a new function reference each call. Connect and disconnect hold different objects. The listener is never removed. Accumulates on each Turbo navigate to the import page.

Fix: store bound ref: `this._boundHandleKeyDown = this.handleKeyDown.bind(this)` in connect, reference it in both addEventListener and removeEventListener.

2. Line 828 — setInterval:
```js
window.setInterval(poll, 1500);
```
Return value (timer handle) is discarded. Cannot be cleared in disconnect(). Multiple 1.5s polling intervals stack up if the user navigates away and returns, each firing network requests indefinitely.

Fix: `this._polishInterval = window.setInterval(poll, 1500)` and `if (this._polishInterval) clearInterval(this._polishInterval)` in disconnect().

**Why:** Classic .bind(this) listener leak. The setInterval is in the `startPolish` method which is called on demand and not tied to the Stimulus lifecycle.

**How to apply:** Whenever reviewing a Stimulus controller that calls .bind(this) inline in addEventListener, verify the bound ref is stored and reused in removeEventListener. Same applies to any setInterval outside the standard pollTimer pattern.
