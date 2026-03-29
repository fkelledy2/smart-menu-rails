---
name: generate_pairings_controller creates duplicate Bootstrap Modal instances
description: showModal() calls new bootstrap.Modal(this.modalTarget) every time — creates a new instance without destroying the old one
type: project
---

In `app/javascript/controllers/generate_pairings_controller.js` line 116:
```js
showModal() {
  const modal = new bootstrap.Modal(this.modalTarget);
  modal.show();
}
```

Every call to `generate()` creates a brand-new Bootstrap Modal instance on the same DOM element. Bootstrap stores the first instance in a WeakMap — subsequent `new` calls create orphaned instances. This causes:
1. Multiple backdrop overlays accumulating on the page
2. `modal.hide()` on the orphaned instance does nothing (the live instance is a different object)
3. The modal cannot be dismissed after the second generate click

**Fix**: use `bootstrap.Modal.getOrCreateInstance(this.modalTarget)` which returns the existing instance if one exists:
```js
showModal() {
  const modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget);
  modal.show();
}
```

**File**: `app/javascript/controllers/generate_pairings_controller.js` line 116
