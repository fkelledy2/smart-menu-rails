---
name: Stimulus undeclared target descriptor in view
description: data-crm-kanban-target="column" in index.html.erb but 'column' not declared in static targets — Stimulus logs warnings, data-transition-url never read
type: project
---

`app/views/admin/crm/leads/index.html.erb` had `data-crm-kanban-target="column"` and `data-transition-url` on the column wrapper div, but `crm_kanban_controller.js` only declares `static targets = ['cardList']`. Stimulus logs a warning for each unknown target. The `data-transition-url` was also dead — the JS hardcodes `/admin/crm/leads/${leadId}/transition` rather than reading from the element.

**Fix:** Remove both `data-crm-kanban-target="column"` and `data-transition-url` from the column div in the view.

**How to apply:** When adding Stimulus targets, always verify the target name appears in `static targets = [...]` in the corresponding controller.
