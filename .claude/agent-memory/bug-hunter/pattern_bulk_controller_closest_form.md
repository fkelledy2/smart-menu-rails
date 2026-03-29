---
name: Bulk controller closest form bug
description: menuitems-bulk and menusections-bulk call this.element.closest('form') but the controller div contains the form as a child — closest() only searches ancestors
type: project
---

In both `menuitems_bulk_controller.js` and `menusections_bulk_controller.js`, `confirmModalApply` ends with:

```js
const form = this.element.closest('form');
if (form) form.requestSubmit();
```

`this.element` is the `<div data-controller="menuitems-bulk">` (or `menusections-bulk`). The `<form>` is a direct child of this div. `Element.closest()` only traverses the ancestor chain — it never searches descendants. So `form` is always `null` and `requestSubmit()` is never called.

**Result**: confirming a bulk action (archive, set status, set food type, set alcoholic) in the modal does nothing. The form is never submitted.

**Fix**: use `this.element.querySelector('form')` instead of `this.element.closest('form')`.

**Files**:
- `app/javascript/controllers/menuitems_bulk_controller.js` line 162
- `app/javascript/controllers/menusections_bulk_controller.js` line 133
