---
name: Payments::RefundsController unguarded find + missing authenticate_user!
description: RefundsController used PaymentAttempt.find (500 on bad ID) and had no authenticate_user! before_action
type: feedback
---

`Payments::RefundsController#create` (line 11) used `.find(params[:payment_attempt_id])` which raises `RecordNotFound` (500) when the ID doesn't exist or is out of scope. The controller also had no explicit `authenticate_user!` before_action — access was guarded only by `ensure_admin!` which does NOT require authentication (only checks `current_user&.super_admin?`).

**Fix:** Changed `.find` to `.find_by(id:)` with explicit 404 response. Added `authenticate_user!` before_action.

**Why:** `ensure_admin!` calls `current_user&.super_admin?` — the `&.` means an unauthenticated request gets `nil.super_admin?` = nil (falsy), so it redirects to root. But without `authenticate_user!`, the request goes through before Devise sets up `current_user`, and Pundit and other auth helpers may not be properly initialized. Defense in depth requires explicit authentication.

**How to apply:** Controllers with `ensure_admin!` or similar custom guards should still have `authenticate_user!` as the first line of defense.
