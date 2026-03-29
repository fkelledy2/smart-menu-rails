---
name: intents_create_bang_not_idempotent
description: Payments::IntentsController uses PaymentAttempt.create! with a deterministic idempotency key — duplicate requests (e.g. wallet double-tap) hit unique constraint and return 500 instead of reusing the existing attempt
type: project
---

`app/controllers/payments/intents_controller.rb` line 35:
```ruby
idempotency_key = "stripe_intent:#{@ordr.id}:#{amount}:#{currency}"
payment_attempt = PaymentAttempt.create!(...)
```

The key is deterministic (same ordr + amount + currency = same key). PaymentAttempt has a unique index on `idempotency_key`. A second call with identical parameters raises `ActiveRecord::RecordNotUnique`, causing an unhandled 500.

The checkout_session path correctly uses `find_or_create_by!` for this reason.

**Why:** The intents path was added separately and did not follow the idempotency pattern established in checkout_session.
**How to apply:** Replace `create!` with `find_or_create_by!(idempotency_key: idempotency_key) do |pa| ... end` as done in the checkout_session path.
