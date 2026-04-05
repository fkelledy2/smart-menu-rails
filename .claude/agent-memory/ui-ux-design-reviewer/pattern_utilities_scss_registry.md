---
name: Custom utility classes registry (_utilities.scss)
description: Non-Bootstrap utility classes defined in app/assets/stylesheets/components/_utilities.scss — reference before adding inline styles
type: project
---

Before adding an inline style to any view, check `_utilities.scss` for an existing class. As of 2026-04-04, the following custom utilities are defined:

**Typography size one-offs** (below Bootstrap's .small):
- `.fs-10` — 0.625rem (tiny badge labels)
- `.fs-11` — 0.6875rem (CRM column headers)
- `.fs-12` — 0.75rem (timestamps, metadata)
- `.fs-13` — 0.8125rem (secondary body text)
- `.fs-build` — 0.65rem (footer build number)
- `.fs-icon-lg` — 3rem (large Bootstrap Icon display)
- `.fs-icon-xl` — 4rem (extra-large Bootstrap Icon display)

**Max-width wrappers** (replace `style="max-width: Xpx"`):
- `.mw-560`, `.mw-600`, `.mw-640`, `.mw-680`, `.mw-760`, `.mw-800`, `.mw-900`, `.mw-960`

**Max-height scrollable containers** (replace `style="max-height: X"`):
- `.mh-9rem` — 9rem (approval payload pre blocks)
- `.mh-12rem` — 12rem (artifact content pre blocks)
- `.mh-400` — 400px (optimization review preview list)

**Fixed-width inputs** (replace `style="width: Xpx"` in tables):
- `.w-120` — 120px (coefficient number inputs in tables)

**White-space utilities**:
- `.ws-pre-wrap` — white-space: pre-wrap (note body text, preserves newlines)
- `.wb-break-all` — word-break: break-all (JWT token display)

**Letter-spacing**:
- `.ls-wide` — letter-spacing: 0.05em (section label uppercase headings)
- `.text-kanban-header` — 0.6875rem + letter-spacing 0.08em (CRM kanban column headers)

**CRM-specific components**:
- `.crm-kanban-column` — column background, border, transition states
- `.crm-lead-card` — card background, shadow on hover, sortable states

**Profitability nav icons**:
- `.profitability-nav-icon--{primary,success,warning,info,purple}`
