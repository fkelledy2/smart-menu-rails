---
name: Testimonials Missing Authorize
description: TestimonialsController update, destroy, and index all missing authorize — any authenticated user could mutate any testimonial
type: project
---

TestimonialsController had three missing `authorize` calls:

1. `update` — no `authorize @testimonial` call; any authenticated user could PATCH any testimonial
2. `destroy` — no `authorize @testimonial` call; `after_action :verify_authorized` caught this as `AuthorizationNotPerformedError` at runtime
3. `index` — `after_action :verify_authorized, except: [:index]` exempted index from verification; combined with `policy_scope`, non-admins could reach the testimonials management page even though `index?` is admin-only

**Fix:** Added `authorize Testimonial` in `index`, `authorize @testimonial` in `update` and `destroy`. Changed `after_action :verify_authorized, except: [:index]` to `after_action :verify_authorized` (no exception).

**Why:** The `except: [:index]` pattern was correct when index used only `policy_scope` without an `authorize` call — but the policy's `index?` was admin-only, so non-admins should have been rejected at the action level, not just filtered by scope.

**How to apply:** When a controller has `after_action :verify_authorized, except: [:index]`, verify that the policy scope is the *only* guard needed, or add `authorize Model` to the index action if `index?` should restrict access.
