# Feature Backlog Writer — Memory Index

## Architecture Decisions
- [arch_crm_admin_only.md](arch_crm_admin_only.md) — CRM is admin-namespace only; no tenant scoping

## Patterns
- [pattern_webhook_verification.md](pattern_webhook_verification.md) — Webhook verification service pattern used across CRM and Strikepay
- [pattern_audit_trail.md](pattern_audit_trail.md) — Dedicated audit model preferred over paper_trail gem for immutable field-change logs
- [pattern_kanban_drag_drop.md](pattern_kanban_drag_drop.md) — Sortable.js + Stimulus + Turbo Stream PATCH for Kanban drag-and-drop
- [pattern_theming_css_custom_properties.md](pattern_theming_css_custom_properties.md) — Theming via data-theme on html + CSS custom property overrides; extends dark-mode pattern

## Deferred Scope
- [deferred_crm_v2.md](deferred_crm_v2.md) — Items consistently deferred from CRM v1 to v2
