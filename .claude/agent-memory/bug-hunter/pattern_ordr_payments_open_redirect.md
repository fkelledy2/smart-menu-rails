---
name: OrdrPaymentsController open redirect via Stripe success_url/cancel_url
description: checkout_session passes user-supplied success_url/cancel_url to Stripe without same-host validation — open redirect after real payment
type: project
---

`app/controllers/ordr_payments_controller.rb` lines 183–184:
```ruby
success_url = params[:success_url].presence || root_url
cancel_url  = params[:cancel_url].presence  || root_url
```

Both values are passed directly to Stripe's checkout session. Stripe redirects the browser to these after payment completes or is cancelled. No same-host validation is performed. An attacker can supply `https://evil.example.com` as `success_url`, causing Stripe to redirect the customer there after completing a real payment — a phishing vector.

The `collect_payment_controller.js` currently sends `window.location.href` for both (safe), but the server endpoint accepts any value.

Fix: validate both URLs are same-host before passing to Stripe:
```ruby
def safe_redirect_url(url, fallback)
  uri = URI.parse(url.to_s)
  return fallback unless uri.host == URI.parse(request.base_url).host
  url
rescue URI::InvalidURIError
  fallback
end
```

**Why:** Payment flow open redirects are higher impact than normal open redirects because they execute immediately after a user hands over money — high phishing potential.

**How to apply:** Any time a payment controller accepts redirect URLs as params, validate same-host. This applies to both Stripe and Square adapter paths.
