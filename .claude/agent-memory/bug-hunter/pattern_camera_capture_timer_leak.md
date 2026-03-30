---
name: camera_capture_controller _showStatus timer not cleared in disconnect()
description: camera_capture_controller.js _showStatus setTimeout not stored or cleared — stale DOM access after Turbo navigation (FIXED)
type: project
---

`camera_capture_controller.js` `_showStatus` method created a `setTimeout` but stored the handle in a local variable rather than `this._statusTimer`, so `disconnect()` could not clear it. The timer callback accessed `this.statusTarget` without a `hasStatusTarget` guard — on Turbo navigation the controller disconnects and the callback fires against a detached element.

**Why:** Two compounding issues: (1) timer handle not stored on `this`, (2) no `hasStatusTarget` guard in the callback. Fixed by: initializing `this._statusTimer = null` in `connect()`, clearing it in `disconnect()`, storing the return value, and adding the `hasStatusTarget` guard in the callback.

**How to apply:** All setTimeout callbacks that touch Stimulus targets must guard with `has*Target` before accessing the target. The timer handle must always be stored on `this` so it can be cleared in `disconnect()`.
