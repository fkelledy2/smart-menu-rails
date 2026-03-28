---
name: btn-danger Used as Brand Primary Button
description: btn-danger is used for primary CTAs on auth (login, signup) and marketing pages — semantically wrong and visually inconsistent with the operator UI
type: project
---

**Rule:** btn-danger should never be used as a primary action button unless the action is genuinely destructive.

**Evidence:** devise/sessions/new, devise/registrations/new, devise/passwords/new, devise/passwords/edit, devise/confirmations/new, devise/unlocks/new, home/index (multiple CTAs), home/demo, restaurants/sections/_import_2025.

**Why:** This appears to be a brand decision (red as brand primary colour on public/marketing pages) that was applied without using the proper Bootstrap variable. The result is: auth buttons render as red (`btn-danger` = #dc3545 in Bootstrap), while the operator dashboard uses `btn-primary` (#007bff Bootstrap blue) or the 2025 custom properties (#2563EB). Three different colours for "primary" depending on context.

**How to apply:** The correct fix is to set $primary in themes/_variables.scss to the mellow.menu brand colour (whatever red/coral tone is intended), then replace all btn-danger CTAs with btn-primary. This unifies the brand colour across all contexts and makes danger correctly mean "destructive".
