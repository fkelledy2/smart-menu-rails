---
name: Razorpay Adapter Pattern Decision
description: How Razorpay integrates into Payments::Orchestrator — enum extension, adapter interface, UPI polling job pattern
type: project
---

Razorpay extends the existing `Payments::Orchestrator` via a new `Payments::Providers::RazorpayAdapter` implementing `BaseAdapter`. `PaymentProfile#primary_provider` gains a `:razorpay` enum value (integer 2). The `razorpay` official Ruby gem is the only new dependency added for this initiative.

**Why:** UPI payments are async (pull-based); no equivalent to Stripe PaymentIntent auto-capture. A `UpiPaymentStatusPollerJob` (Sidekiq, `payments` queue) polls Razorpay Order status every 10s for up to 5 minutes as a fallback to webhooks. `create_and_capture_intent!` raises `NotImplementedError` for Razorpay — UPI does not support it.

**How to apply:** When speccing any India payment feature, assume Razorpay is the provider, route through Orchestrator, and flag that auto-capture intent flow is unavailable. Webhook verification uses `Razorpay::Utility.verify_webhook_signature` on raw request body.
