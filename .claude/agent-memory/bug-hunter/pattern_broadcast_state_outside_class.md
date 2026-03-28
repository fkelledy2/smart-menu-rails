---
name: broadcast_state defined outside OrdrsController class
description: broadcast_state was a top-level Ruby method above the class definition in ordrs_controller.rb — moved inside private section (FIXED)
type: project
---

`app/controllers/ordrs_controller.rb` had `broadcast_state` defined as a **top-level method** (before the `class OrdrsController` declaration). Ruby makes top-level `def` methods private methods on `Object/Kernel`, so it was callable from the controller via inheritance — but this is fragile and non-idiomatic.

The method used `session`, `session.id`, and Rails helpers that are only valid in a controller context. Having it as a top-level method meant it was theoretically callable from anywhere, and would not be visible to IDEs/tooling as a controller method.

**Fix:** Removed the top-level definition and placed `broadcast_state` as a private instance method inside `OrdrsController`.

**Why:** Git history shows the method was extracted above the class during a refactor, likely as an accidental misplacement.

**How to apply:** When a method in a controller uses `session`, `current_user`, or other request-bound helpers, always verify it is defined inside the class. Check `grep -n '^def\|^class\|^end' file.rb` to detect any top-level method leakage. This is the same pattern as the `menuitem.rb` methods-outside-class bug.
