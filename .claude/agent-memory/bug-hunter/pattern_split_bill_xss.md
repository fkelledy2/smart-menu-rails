---
name: split_bill_xss
description: split_bill_controller.js showError injected server error strings into innerHTML without escaping — stored XSS vector
type: feedback
---

`showError(message, details)` built an HTML string from `message` (from `error.message` or `data.error` from server JSON) and `details` array, then assigned it to `this.errorMessageTarget.innerHTML`. Server error messages can contain `<` / `>` characters either from genuine validation messages or from crafted server responses.

**Why:** Template literal string concatenation into innerHTML is always XSS-risky when the data comes from user-influenced sources (server error messages echo back user input).

**How to apply:** Rewrote `showError` using `document.createElement` + `textContent` exclusively. Same fix applied to `menu_import_controller.js` line 636 which injected server validation messages via `innerHTML` in the save-item error handler. (FIXED)
