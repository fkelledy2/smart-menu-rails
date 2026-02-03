# Stripe Webhook Production Issue - Order Not Closing After Payment

## Problem
Orders are not being marked as closed after successful Stripe payment completion in production (Heroku). Works correctly in local development.

## Symptoms
- Payment completes successfully in Stripe
- Order remains in "paid" state but doesn't transition to "closed"
- Local environment works correctly
- Production logs show no webhook events being received

## Root Cause Analysis

### Expected Flow
1. Customer completes payment via Stripe Checkout
2. Stripe sends `checkout.session.completed` webhook to `/payments/webhooks/stripe`
3. `Payments::WebhooksController#stripe` receives webhook
4. `Payments::WebhookIngestJob` processes the event
5. `Payments::Webhooks::StripeIngestor#handle_checkout_session_completed` is called
6. Order events are emitted: `paid` → `closed`
7. `OrderEventProjector.project!` updates order status
8. State is broadcast via ActionCable

### Potential Issues

#### 1. Webhook Not Configured in Stripe Dashboard
**Most Likely Issue**: Production webhook endpoint not registered in Stripe.

**Check**:
- Go to Stripe Dashboard → Developers → Webhooks
- Verify webhook endpoint exists: `https://www.mellow.menu/payments/webhooks/stripe`
- Check if `checkout.session.completed` event is selected
- Verify webhook is in "Live mode" (not test mode)

#### 2. Webhook Secret Mismatch
**Check**:
```bash
# Verify STRIPE_WEBHOOK_SECRET is set in production
heroku config:get STRIPE_WEBHOOK_SECRET -a smart-menus

# Compare with Stripe Dashboard webhook signing secret
# Stripe Dashboard → Developers → Webhooks → [Your Endpoint] → Signing secret
```

#### 3. Webhook Signature Verification Failing
**Symptoms**: Webhooks return 400 Bad Request
**Check production logs for**:
```
[StripeWebhook] Invalid payload/signature
```

#### 4. Job Queue Not Processing
**Check**:
```bash
# Verify worker dyno is running
heroku ps -a smart-menus

# Check for failed jobs
heroku run rails console -a smart-menus
> Payments::WebhookIngestJob.count
> # Check Sidekiq or job backend for failures
```

#### 5. Metadata Missing from Checkout Session
**Check**: Order ID must be in checkout session metadata
```ruby
# In code that creates checkout session:
metadata: {
  order_id: ordr.id.to_s,  # REQUIRED
  # ...
}
```

## Diagnostic Steps

### Step 1: Check Stripe Dashboard
1. Go to https://dashboard.stripe.com/webhooks
2. Verify production webhook exists
3. Check "Events" tab for recent webhook attempts
4. Look for failed deliveries or errors

### Step 2: Check Heroku Config
```bash
# Verify webhook secret is set
heroku config -a smart-menus | grep STRIPE

# Should show:
# STRIPE_SECRET_KEY: sk_live_...
# STRIPE_WEBHOOK_SECRET: whsec_...
```

### Step 3: Check Production Logs
```bash
# Tail production logs
./heroku/production/tail.sh --source app

# Look for webhook events:
# [StripeWebhook] Received event type=checkout.session.completed
# [StripeWebhook] Failed to enqueue ingest job
# [StripeWebhook] Invalid payload/signature
```

### Step 4: Test Webhook Manually
```bash
# From Stripe Dashboard → Webhooks → [Your Endpoint] → Send test webhook
# Select: checkout.session.completed
# Check production logs for processing
```

### Step 5: Verify Order Event Flow
```bash
heroku run rails console -a smart-menus

# Find the order
ordr = Ordr.find(529)  # Use actual order ID from logs

# Check events
ordr.order_events.pluck(:event_type, :created_at)
# Should show: ["paid", ...], ["closed", ...]

# Check current status
ordr.status
# Should be: "closed"

# Check if paid event exists
OrderEvent.where(ordr_id: 529, event_type: 'paid').exists?
# Should be: true

# Check if closed event exists
OrderEvent.where(ordr_id: 529, event_type: 'closed').exists?
# Should be: true
```

## Solutions

### Solution 1: Register Production Webhook in Stripe

1. **Go to Stripe Dashboard**:
   - https://dashboard.stripe.com/webhooks
   - Click "Add endpoint"

2. **Configure Endpoint**:
   - Endpoint URL: `https://www.mellow.menu/payments/webhooks/stripe`
   - Description: "Production Order Webhooks"
   - Events to send:
     - ✅ `checkout.session.completed`
     - ✅ `payment_intent.succeeded`
     - ✅ `charge.refunded`
     - ✅ `account.updated`

3. **Copy Signing Secret**:
   ```bash
   # Set in Heroku
   heroku config:set STRIPE_WEBHOOK_SECRET=whsec_xxx -a smart-menus
   ```

4. **Restart Dynos**:
   ```bash
   heroku restart -a smart-menus
   ```

### Solution 2: Fix Webhook Secret Mismatch

```bash
# Get the correct signing secret from Stripe Dashboard
# Stripe Dashboard → Webhooks → [Your Endpoint] → Signing secret

# Update Heroku config
heroku config:set STRIPE_WEBHOOK_SECRET=whsec_correct_secret -a smart-menus

# Restart app
heroku restart -a smart-menus
```

### Solution 3: Enable Webhook Logging

Add temporary logging to track webhook processing:

```ruby
# In app/controllers/payments/webhooks_controller.rb
def stripe
  payload = request.body.read
  sig_header = request.env['HTTP_STRIPE_SIGNATURE']
  
  # ADD THIS
  Rails.logger.info("[StripeWebhook] Received request from #{request.remote_ip}")
  Rails.logger.info("[StripeWebhook] Signature present: #{sig_header.present?}")
  
  evt = build_stripe_event(payload, sig_header)
  return head :bad_request unless evt
  
  # ADD THIS
  Rails.logger.info("[StripeWebhook] Event validated: type=#{evt.type} id=#{evt.id}")
  
  # ... rest of method
end
```

### Solution 4: Manual Order Closure (Temporary Workaround)

If webhooks can't be fixed immediately:

```bash
heroku run rails console -a smart-menus

# Find paid but not closed orders
paid_orders = Ordr.joins(:order_events)
  .where(order_events: { event_type: 'paid' })
  .where.not(id: OrderEvent.where(event_type: 'closed').select(:ordr_id))

# Close them manually
paid_orders.each do |ordr|
  OrderEvent.emit!(
    ordr: ordr,
    event_type: 'closed',
    entity_type: 'order',
    entity_id: ordr.id,
    source: 'manual',
    idempotency_key: "manual:closed:#{ordr.id}",
    payload: { reason: 'manual_closure_after_payment' }
  )
  OrderEventProjector.project!(ordr.id)
  puts "Closed order #{ordr.id}"
end
```

## Verification

After implementing the fix:

1. **Create Test Order**:
   - Place order in production
   - Complete payment via Stripe

2. **Check Webhook Delivery**:
   - Stripe Dashboard → Webhooks → [Endpoint] → Events
   - Should show successful delivery (200 OK)

3. **Check Production Logs**:
   ```bash
   ./heroku/production/tail.sh --source app
   
   # Should see:
   # [StripeWebhook] Received event type=checkout.session.completed
   # [StripeWebhook] Event validated
   # OrderEvent emitted: paid
   # OrderEvent emitted: closed
   ```

4. **Verify Order Status**:
   ```bash
   heroku run rails console -a smart-menus
   
   ordr = Ordr.last
   ordr.status  # Should be "closed"
   ordr.order_events.pluck(:event_type)  # Should include ["paid", "closed"]
   ```

## Prevention

### 1. Add Webhook Monitoring
Create a monitoring script to alert on webhook failures:

```ruby
# lib/tasks/stripe_webhook_health.rake
namespace :stripe do
  desc "Check webhook health"
  task webhook_health: :environment do
    # Check for recent paid orders without closed events
    recent_paid = Ordr.joins(:order_events)
      .where(order_events: { event_type: 'paid' })
      .where('order_events.created_at > ?', 1.hour.ago)
      .where.not(id: OrderEvent.where(event_type: 'closed').select(:ordr_id))
    
    if recent_paid.any?
      puts "⚠️  WARNING: #{recent_paid.count} paid orders not closed"
      # Send alert to Sentry/Slack
    else
      puts "✅ All recent paid orders are closed"
    end
  end
end
```

### 2. Add Webhook Endpoint Test

```ruby
# test/integration/stripe_webhook_test.rb
test "production webhook endpoint is accessible" do
  skip unless Rails.env.production?
  
  response = Net::HTTP.get_response(URI('https://www.mellow.menu/payments/webhooks/stripe'))
  assert_equal 405, response.code.to_i  # Method not allowed (GET not supported)
end
```

### 3. Document Webhook Setup

Add to deployment checklist:
- [ ] Verify Stripe webhook endpoint registered
- [ ] Verify STRIPE_WEBHOOK_SECRET matches Stripe Dashboard
- [ ] Test webhook delivery with Stripe test event
- [ ] Monitor first few production orders

## Related Files

- `app/controllers/payments/webhooks_controller.rb` - Webhook receiver
- `app/services/payments/webhooks/stripe_ingestor.rb` - Event processor
- `app/jobs/payments/webhook_ingest_job.rb` - Background job
- `config/routes.rb` - Webhook route definition

## References

- [Stripe Webhook Documentation](https://stripe.com/docs/webhooks)
- [Stripe Webhook Best Practices](https://stripe.com/docs/webhooks/best-practices)
- [Heroku Config Vars](https://devcenter.heroku.com/articles/config-vars)
