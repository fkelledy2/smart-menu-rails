# Stripe Webhook Production Checklist

## Current Issue
✅ Webhook endpoint responds to pings (signature verification working after fix)
❌ No `checkout.session.completed` events received when payment completes
❌ Orders not closing after payment

## Critical Checks

### 1. Verify Webhook is in LIVE MODE (not Test Mode)

**This is the most common issue!**

Go to: https://dashboard.stripe.com/webhooks

**Check:**
- [ ] Toggle at top right shows **"Viewing live data"** (not "Viewing test data")
- [ ] Your webhook endpoint shows in the live webhooks list
- [ ] Endpoint URL: `https://www.mellow.menu/payments/webhooks/stripe`

**If you see your webhook only in test mode:**
1. Switch to "Viewing live data"
2. Create a NEW webhook endpoint for live mode
3. Use the LIVE mode signing secret in Heroku

### 2. Verify Events are Selected

In your webhook endpoint settings:

**Required events:**
- [ ] `checkout.session.completed` ← **CRITICAL**
- [ ] `payment_intent.succeeded`
- [ ] `charge.refunded`
- [ ] `account.updated`

**If events aren't selected:**
1. Click your webhook endpoint
2. Click "Add events"
3. Select the events above
4. Save

### 3. Verify API Keys Match Mode

**Check your Heroku config:**
```bash
heroku config:get STRIPE_SECRET_KEY -a smart-menus
```

**Should start with:**
- `sk_live_...` for production (live mode)
- `sk_test_...` for testing (test mode)

**If using test key in production:**
- Stripe won't send live webhooks to test mode endpoints
- You need to use live keys and live webhook endpoint

### 4. Check Stripe Dashboard Event Logs

Go to: https://dashboard.stripe.com/webhooks/[your-endpoint-id]

**Click "Events" tab:**
- [ ] Do you see `checkout.session.completed` events?
- [ ] Are they showing as "Succeeded" (200 OK)?
- [ ] Or showing as "Failed" with error?

**If no events appear:**
- Webhook isn't being triggered (likely mode mismatch)

**If events show as failed:**
- Click the event to see the error
- Check response body and status code

### 5. Verify Checkout Session Uses Correct API Key

The checkout session must be created with the SAME mode (live/test) as your webhook:

```bash
# Check production logs when creating checkout
heroku logs --tail -a smart-menus | grep StripeCheckout

# Should show:
# [StripeCheckout] Created session (ordr_id=529 session_id=cs_live_...)
#                                                              ^^^^
#                                                              Must be "live" not "test"
```

## Quick Diagnostic Script

Run this to check your current configuration:

```bash
#!/bin/bash
echo "==> Checking Stripe Configuration"
echo ""

# Check API key mode
SECRET_KEY=$(heroku config:get STRIPE_SECRET_KEY -a smart-menus)
if [[ "$SECRET_KEY" == sk_live_* ]]; then
  echo "✅ Using LIVE API key"
  MODE="live"
elif [[ "$SECRET_KEY" == sk_test_* ]]; then
  echo "⚠️  Using TEST API key in production!"
  MODE="test"
else
  echo "❌ Invalid or missing API key"
  exit 1
fi

echo ""
echo "==> Your webhook endpoint should be in: $MODE mode"
echo ""
echo "Next steps:"
echo "1. Go to: https://dashboard.stripe.com/webhooks"
echo "2. Toggle to: 'Viewing $MODE data'"
echo "3. Verify your webhook exists in this mode"
echo "4. If not, create a new webhook endpoint for $MODE mode"
echo "5. Update STRIPE_WEBHOOK_SECRET with the $MODE webhook's signing secret"
```

## Most Likely Solution

Based on your symptoms, the issue is almost certainly:

**Your webhook is configured in TEST mode, but you're processing LIVE payments**

### Fix:

1. **Check current mode:**
   ```bash
   heroku config:get STRIPE_SECRET_KEY -a smart-menus
   ```

2. **If it starts with `sk_live_`:**
   - Go to: https://dashboard.stripe.com/webhooks
   - Toggle to: **"Viewing live data"** (top right)
   - Check if your webhook exists
   - If NOT, create a new webhook for live mode
   - Copy the LIVE webhook's signing secret
   - Update Heroku:
     ```bash
     heroku config:set STRIPE_WEBHOOK_SECRET=whsec_live_xxx -a smart-menus
     heroku restart -a smart-menus
     ```

3. **If it starts with `sk_test_`:**
   - You're using test keys in production (not recommended)
   - Either:
     - Switch to live keys for production, OR
     - Use test mode webhook endpoint

## Verification After Fix

1. **Create a test order and pay:**
   - Complete payment through Stripe Checkout
   
2. **Check webhook was received:**
   ```bash
   heroku logs --tail -a smart-menus | grep StripeWebhook
   
   # Should see:
   # [StripeWebhook] Received event type=checkout.session.completed id=evt_xxx livemode=true
   ```

3. **Check order closed:**
   ```bash
   heroku run rails console -a smart-menus
   
   ordr = Ordr.last
   ordr.status  # Should be "closed"
   ordr.order_events.pluck(:event_type)  # Should include ["paid", "closed"]
   ```

4. **Check Stripe Dashboard:**
   - Go to: Webhooks → Your endpoint → Events
   - Should show successful delivery (200 OK)

## Common Mistakes

❌ **Webhook in test mode, payments in live mode**
- Stripe won't send live events to test webhooks

❌ **Wrong signing secret**
- Test webhook secret used for live webhook (or vice versa)

❌ **Events not selected**
- `checkout.session.completed` not checked in webhook settings

❌ **Multiple webhook endpoints**
- Old test endpoint interfering with live endpoint

❌ **Webhook disabled**
- Endpoint exists but is disabled in Stripe Dashboard

## Support Resources

- [Stripe Webhooks Documentation](https://stripe.com/docs/webhooks)
- [Testing Webhooks](https://stripe.com/docs/webhooks/test)
- [Webhook Best Practices](https://stripe.com/docs/webhooks/best-practices)
