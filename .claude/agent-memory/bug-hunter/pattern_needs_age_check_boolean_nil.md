---
name: needs_age_check boolean logic bug
description: SmartmenusController used !x.nil? to test a boolean — always true even when no unacknowledged age-check events existed (FIXED)
type: project
---

`app/controllers/smartmenus_controller.rb` line 466 (in `call_show_pipeline`):

```ruby
# BEFORE (broken): !x.nil? is always true for booleans (true.nil? == false, false.nil? == false)
@needs_age_check = !(@openOrder && AlcoholOrderEvent.exists?(...)).nil?

# AFTER (fixed):
@needs_age_check = @openOrder.present? && AlcoholOrderEvent.exists?(...)
```

When `@openOrder` was present but had **no** unacknowledged events, `AlcoholOrderEvent.exists?` returned `false`. Then `(@openOrder && false)` = `false`, and `(!false.nil?)` = `true` — so the age-check UI was shown spuriously.

**Why:** `!x.nil?` pattern is idiomatic for "is x present?", but `.nil?` on a boolean is always `false`, so the negation is always `true`. Only valid when `x` could be `nil`; never use it on `&&` expressions whose final value may be a boolean.

**How to apply:** Never use `!(...).nil?` when the expression can return `false`. Use `.present?`, `!!`, or a plain truthiness check instead.
