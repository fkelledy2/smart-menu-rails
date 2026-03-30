---
name: customer_auto_pay_controller missing disconnect() for _statusTimeout
description: customer_auto_pay_controller.js set _statusTimeout in _showStatus but had no disconnect() — timer leaked on Turbo navigation (FIXED)
type: project
---

`customer_auto_pay_controller.js` stored a timeout handle in `this._statusTimeout` inside `_showStatus()` but had no `disconnect()` lifecycle method. On Turbo navigation, the controller disconnects but the pending timer fires and attempts to access `this.statusMessageTarget`, which is now detached.

**Why:** Same leak class as `auto_pay_controller.js` (already in memory). Any setTimeout stored on `this` needs a matching `clearTimeout` in `disconnect()`.

**How to apply:** Grep all Stimulus controllers for `setTimeout` assignments to `this._*`. If there is no `disconnect()` that clears them, it is a bug. Fixed by adding `disconnect() { clearTimeout(this._statusTimeout); }`.
