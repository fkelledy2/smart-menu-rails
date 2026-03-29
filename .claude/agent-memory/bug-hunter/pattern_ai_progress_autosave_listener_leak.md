---
name: ai_progress_controller.js global autosave listener never removed on disconnect
description: _bindAutosave adds a document-level change listener that persists after controller disconnect; also statusTimeout in auto_pay_controller not cleared on disconnect
type: feedback
---

`ai_progress_controller.js#_bindAutosave` (line 397) registers a document-level `change` event listener. It guards against double-registration with `dataset.autosaveBound = 'true'`, but never removes the listener in `disconnect()`. On Turbo navigation the controller disconnects but the listener remains, keeping the closure and `document.documentElement.dataset.autosaveBound` set permanently. Subsequent controller instances won't re-register (good), but the original listener captures the closure's `this` reference keeping the first controller instance alive.

`auto_pay_controller.js#_showStatus` (line 146) sets `this._statusTimeout` but `disconnect()` does not call `clearTimeout(this._statusTimeout)` — the timer can fire after the element is removed.

**Why:** Both are defensive coding gaps rather than behavioral bugs, but they can cause unexpected callbacks and memory growth in long-running sessions.

**How to apply:** In `ai_progress_controller.js#disconnect()`, do not try to remove the global change listener (it's shared and intentionally persistent), but document this clearly. For `auto_pay_controller.js#disconnect()`, add `if (this._statusTimeout) clearTimeout(this._statusTimeout)`.
