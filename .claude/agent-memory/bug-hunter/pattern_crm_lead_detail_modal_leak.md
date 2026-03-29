---
name: crm_lead_detail_controller.js creates new bootstrap.Modal on every click — duplicate instances accumulate
description: openConvertModal calls new window.bootstrap.Modal(modal) each time — same pattern as generate_pairings_controller; should use getOrCreateInstance to avoid duplicate modal instances
type: project
---

In app/javascript/controllers/crm_lead_detail_controller.js line 19:
```js
const bsModal = new window.bootstrap.Modal(modal);
```

Every click of the Convert button creates a new Bootstrap Modal instance on the same DOM element. Bootstrap does not automatically destroy previous instances. This causes: multiple backdrop overlays, inability to close the modal after repeated clicks, and memory accumulation.

Fix: use window.bootstrap.Modal.getOrCreateInstance(modal) instead of new window.bootstrap.Modal(modal).

**Why:** Bootstrap Modal constructor does not deduplicate — getOrCreateInstance is the correct API for this pattern.
**How to apply:** All modal show() calls from Stimulus controllers must use getOrCreateInstance.
