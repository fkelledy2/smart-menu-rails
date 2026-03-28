---
name: Page-Scoped Style Blocks in Partials
description: Multiple <style> blocks embedded directly in section partials — creates load-order issues, defeats CSS caching, and makes styles invisible during code review
type: project
---

Files confirmed to contain embedded <style> blocks:
- app/views/restaurants/sections/_menus_2025.html.erb — two separate <style> blocks (lines 75-96 and 391-718), defining .menu-card, .drag-handle, .menu-row-mobile etc.
- app/views/restaurants/sections/_localization_2025.html.erb — <style> block defining .quick-action-btn.disabled
- app/views/admin/crm/leads/index.html.erb — <style> block defining .crm-kanban-column, .crm-lead-card

**Problems:**
1. Styles are not cached with the asset pipeline
2. If a partial renders multiple times (e.g., in a Turbo stream), styles are injected multiple times
3. Styles are invisible to the SCSS linter and any design system auditing
4. The .quick-action-btn.disabled definition appears in BOTH _menus_2025 and _localization_2025 — exact duplicate

**How to apply:** Extract page-scoped styles into the relevant SCSS file (either a component SCSS file like _sidebar_2025.scss or a new _menus.scss). The .quick-action-btn.disabled rule should live in _sidebar_2025.scss next to the base .quick-action-btn definition. CRM kanban styles should move to a _crm.scss or be converted to Bootstrap utility classes.
