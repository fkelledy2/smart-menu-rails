---
name: SCSS Variables State
description: themes/_variables.scss uses Bootstrap 4-era default values and is not customised for mellow.menu — the brand theme has never been applied at the variable level
type: project
---

Current state of themes/_variables.scss:
- $primary: #007bff — Bootstrap 4 default (Bootstrap 5 default is #0d6efd)
- $success: #28a745 — Bootstrap 4 default
- $box-shadow-sm uses rgb() 4-arg notation which SassC may reject (feedback memory: use rgba())
- $btn-box-shadow uses rgb() 4-arg notation — same issue
- Font: system font stack only, no Inter or custom mellow.menu font
- Border-radius: .375rem (Bootstrap 5 default) — not customised
- The file has commented-out "example" theme variations (Material, Corporate, Modern/Minimal, Dark) suggesting it was scaffolded but never actually configured

Key issue: Since $primary is set before Bootstrap imports, ALL Bootstrap-generated utility classes use the wrong primary colour (#007bff). The 2025 system uses --color-primary: #2563EB. These are visually different blues appearing on the same pages.

Recommended fix for mellow.menu brand:
- Identify the actual brand colour (the red/coral used on marketing pages as btn-danger appears to be the intended brand primary)
- Set $primary to that colour in _variables.scss
- This will cascade through btn-primary, text-primary, bg-primary, border-primary etc.
- Align --color-primary in design_system_2025.scss to the same value
- Remove btn-danger usage from auth/CTA contexts
