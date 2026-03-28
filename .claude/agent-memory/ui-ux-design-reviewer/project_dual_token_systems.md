---
name: Dual Token Systems
description: Two competing design token systems exist — Bootstrap SCSS variables and CSS custom properties — causing colour and spacing inconsistency
type: project
---

**The problem:** The codebase runs two parallel design token systems simultaneously:

System 1 — Bootstrap SCSS variables in themes/_variables.scss:
- $primary: #007bff (Bootstrap 4-era blue)
- $success: #28a745, $danger: #dc3545 etc.
- These feed Bootstrap's generated utility classes (.text-primary, .bg-success, etc.)

System 2 — CSS custom properties in design_system_2025.scss:
- --color-primary: #2563EB (Tailwind blue-600)
- --color-success: #10B981 (Tailwind emerald-500)
- --color-danger: #EF4444 (Tailwind red-500)
- These feed custom component classes (.card-app, .sidebar-link, .quick-action-btn, etc.)

The two systems are not aligned — e.g., Bootstrap's $success (#28a745) is a different green from --color-success (#10B981). Any component mixing Bootstrap classes with custom 2025 classes will have visual inconsistency.

Additionally, btn-danger is being used as the brand primary action button throughout auth (login, signup, password reset) and marketing pages — a third "primary" colour (red).

**Why:** The 2025 design system was introduced to improve on the Bootstrap defaults, but the Bootstrap variable overrides in _variables.scss were never updated to match.

**How to apply:** When recommending colour changes, always target themes/_variables.scss first (map mellow.menu brand colours to Bootstrap variables), then remove the redundant CSS custom property equivalents from design_system_2025.scss. Never recommend adding new hardcoded colour values.
