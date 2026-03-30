---
name: Payments::SubscriptionsController open redirect via Stripe success/cancel/return URLs
description: SubscriptionsController passed user-supplied success_url/cancel_url/return_url to Stripe without same-host validation
type: project
---

`Payments::SubscriptionsController#start` accepted `params[:success_url]` and `params[:cancel_url]` and passed them directly to `Stripe::Checkout::Session.create`. Similarly, `#portal` passed `params[:return_url]` to `Stripe::BillingPortal::Session.create`. After Stripe checkout, users are redirected to these URLs — so an attacker could supply any external URL to redirect victims post-payment.

Fixed by replacing `.presence || default_url` with `url_from(params[:url]) || default_url` in both actions.

**Why:** `url_from` validates the URL is same-host, returning nil for external URLs. This is the Rails 7.2 canonical approach (same as `redirect_back_or_to`).

**How to apply:** Any time a controller receives a URL parameter that is later used in a redirect (even indirectly via Stripe), validate with `url_from`.
