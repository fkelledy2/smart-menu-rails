#!/usr/bin/env bash
set -euo pipefail

APP_NAME="smart-menus"

echo "==> Stripe Configuration Diagnostic for Production"
echo ""

# Check API key
echo "1. Checking Stripe API Key Mode:"
SECRET_KEY=$(heroku config:get STRIPE_SECRET_KEY -a "${APP_NAME}" 2>/dev/null || echo "NOT_SET")

if [[ "$SECRET_KEY" == "NOT_SET" ]]; then
  echo "   ❌ STRIPE_SECRET_KEY not set!"
  exit 1
elif [[ "$SECRET_KEY" == sk_live_* ]]; then
  echo "   ✅ Using LIVE mode (sk_live_...)"
  MODE="live"
elif [[ "$SECRET_KEY" == sk_test_* ]]; then
  echo "   ⚠️  Using TEST mode (sk_test_...)"
  MODE="test"
else
  echo "   ❌ Invalid API key format"
  exit 1
fi

echo ""

# Check webhook secret
echo "2. Checking Webhook Secret:"
WEBHOOK_SECRET=$(heroku config:get STRIPE_WEBHOOK_SECRET -a "${APP_NAME}" 2>/dev/null || echo "NOT_SET")

if [[ "$WEBHOOK_SECRET" == "NOT_SET" ]]; then
  echo "   ❌ STRIPE_WEBHOOK_SECRET not set!"
elif [[ "$WEBHOOK_SECRET" == whsec_* ]]; then
  echo "   ✅ Webhook secret is set (whsec_...)"
else
  echo "   ⚠️  Webhook secret doesn't start with 'whsec_'"
fi

echo ""
echo "==> CRITICAL NEXT STEPS:"
echo ""
echo "You are using Stripe in: $MODE mode"
echo ""
echo "1. Go to Stripe Dashboard:"
echo "   https://dashboard.stripe.com/webhooks"
echo ""
echo "2. Toggle to: 'Viewing $MODE data' (top right corner)"
echo ""
echo "3. Check if webhook exists:"
echo "   URL: https://www.mellow.menu/payments/webhooks/stripe"
echo ""
echo "4. If webhook DOES NOT exist in $MODE mode:"
echo "   - Click 'Add endpoint'"
echo "   - URL: https://www.mellow.menu/payments/webhooks/stripe"
echo "   - Events to send:"
echo "     ✓ checkout.session.completed"
echo "     ✓ payment_intent.succeeded"
echo "     ✓ charge.refunded"
echo "     ✓ account.updated"
echo "   - Click 'Add endpoint'"
echo ""
echo "5. Copy the signing secret:"
echo "   - Click on your webhook endpoint"
echo "   - Click 'Reveal' next to 'Signing secret'"
echo "   - Copy the secret (starts with whsec_)"
echo ""
echo "6. Update Heroku:"
echo "   heroku config:set STRIPE_WEBHOOK_SECRET=whsec_xxx -a smart-menus"
echo "   heroku restart -a smart-menus"
echo ""
echo "7. Test the webhook:"
echo "   - In Stripe Dashboard, click your webhook"
echo "   - Click 'Send test webhook'"
echo "   - Select: checkout.session.completed"
echo "   - Check production logs:"
echo "     ./heroku/production/tail.sh | grep StripeWebhook"
echo ""
echo "==> Common Issue:"
echo "If you have a webhook in TEST mode but are using LIVE keys,"
echo "or vice versa, webhooks will NOT be delivered!"
echo ""
echo "The webhook endpoint MUST be in the SAME mode as your API keys."
