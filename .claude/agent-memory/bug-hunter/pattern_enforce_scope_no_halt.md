---
name: enforce_scope! does not halt action execution
description: JwtAuthenticated#enforce_scope! calls render but does not return — the action body continues to execute after a scope denial
type: feedback
---

`JwtAuthenticated#enforce_scope!` (and the identical copy in `Api::V1::BaseController#enforce_scope!`) calls `render json: ..., status: :forbidden` but does NOT `return` afterwards. In `Api::V1::Analytics::DashboardController#dashboard`, the pattern is:

```ruby
enforce_scope!('analytics:read')
render json: { ... }  # executes even on scope denial
```

This causes a "double render" `AbstractController::DoubleRenderError` in development and silently drops the 403 body in production (Rails ignores the second render attempt after the first).

**Why:** `enforce_scope!` was modelled as a guard method, but unlike `before_action`, inline method calls inside an action do not automatically halt execution.

**How to apply:** The correct pattern is `return enforce_scope!('analytics:read')` at the call site, OR add an explicit `return` inside `enforce_scope!` after the render call (but that only works if callers always use the return value). The safest fix is always `return enforce_scope!(...)` at each call site in `dashboard` and any future analytics actions.
