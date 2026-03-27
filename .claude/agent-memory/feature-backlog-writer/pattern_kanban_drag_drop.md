---
name: Kanban drag-and-drop pattern
description: Sortable.js + Stimulus controller + Turbo Stream PATCH for Kanban boards — no React
type: project
---

Kanban board drag-and-drop uses:
- **Sortable.js** (MIT, zero-dependency JS library) — initialised by a Stimulus controller on each stage column
- On drag end: Stimulus controller fires a `fetch` PATCH to a `transition` member route with CSRF token and target stage
- On success: server responds with a Turbo Stream that replaces the moved card in the DOM
- On failure: Stimulus controller reverts the card to its original column and shows a flash toast

No React, no websockets, no ActionCable required for single-user Kanban views.

**Why:** Consistent with the project's Hotwire-first frontend policy. React was never considered. ActionCable is deferred to v2 for multi-user realtime sync.

**How to apply:** Any future Kanban or drag-and-drop feature should follow this pattern. Confirm Sortable.js is in package.json before building (`yarn list sortablejs`); if absent, add via `yarn add sortablejs`.
