---
name: OcrMenuSectionsController double authorization — admin gets 403
description: The update action calls Pundit authorize (which allows admin) then independently checks owns_section? (which requires restaurant ownership) — admin users pass Pundit but get a 403 from the manual check
type: project
---

`Api::V1::OcrMenuSectionsController#update` (in `app/controllers/api/v1/ocr_menu_sections_controller.rb`) does:

1. `authorize @section` — Pundit; `OcrMenuSectionPolicy#update?` allows `owner? || admin?`
2. `unless owns_section?(current_user, @section)` — manual check; `owns_section?` only checks `restaurant.user_id == user.id`

An admin user (one with `user.admin? == true`) passes step 1 but fails step 2 because `owns_section?` doesn't include an admin bypass. Result: admin gets 403 even though Pundit authorized them.

**Why:** The manual `owns_section?` guard was added defensively but duplicates and contradicts the Pundit policy, which already handles admin access.

**How to apply:** Remove the `unless owns_section?` manual check entirely — Pundit already enforces the policy. The test debug block should also be removed in production.
