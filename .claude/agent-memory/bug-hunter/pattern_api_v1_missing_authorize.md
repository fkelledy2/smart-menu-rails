---
name: API V1 controllers missing Pundit authorize calls
description: Multiple V1 controllers have actions that skip authorize, causing Pundit::AuthorizationNotPerformedError (500) for non-super-admins
type: project
---

The following controller actions are missing `authorize` calls but have `after_action :verify_authorized` from `Api::V1::BaseController`:

- `Api::V1::MenusController#index` — no authorize; `MenuPolicy#index?` requires user.present?
- `Api::V1::MenuItemsController#index` — no authorize at all
- `Api::V1::VisionController#detect_menu_items` — no authorize (VisionPolicy#detect_menu_items? exists but is never called)

All three will raise `Pundit::AuthorizationNotPerformedError` after a successful DB query, returning a 500 to non-super-admin users.

**Why:** These appear to be actions that were added without a corresponding authorize call.

**How to apply:** When V1 API endpoints return 500 for authenticated non-super-admin users, check for missing authorize calls against the `after_action :verify_authorized` requirement.
