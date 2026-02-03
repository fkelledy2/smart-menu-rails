#!/usr/bin/env bash
set -euo pipefail

# Fix Stripe Webhook Secret in Production
# Usage: heroku/production/fix_stripe_webhook.sh

APP_NAME="smart-menus"

echo "==> Fixing Stripe Webhook Configuration for Production"
echo ""
echo "⚠️  IMPORTANT: You need the webhook signing secret from Stripe Dashboard"
echo ""
echo "Steps to get the correct signing secret:"
echo "1. Go to: https://dashboard.stripe.com/webhooks"
echo "2. Find your production webhook endpoint: https://www.mellow.menu/payments/webhooks/stripe"
echo "3. Click on the endpoint"
echo "4. Click 'Reveal' next to 'Signing secret'"
echo "5. Copy the secret (starts with whsec_)"
echo ""
echo "Current webhook secret in Heroku:"
heroku config:get STRIPE_WEBHOOK_SECRET -a "${APP_NAME}" || echo "(not set)"
echo ""
read -p "Enter the correct Stripe webhook signing secret (whsec_...): " webhook_secret

if [[ -z "$webhook_secret" ]]; then
  echo "❌ No secret provided. Exiting."
  exit 1
fi

if [[ ! "$webhook_secret" =~ ^whsec_ ]]; then
  echo "⚠️  Warning: Secret doesn't start with 'whsec_' - are you sure this is correct?"
  read -p "Continue anyway? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo ""
echo "==> Setting STRIPE_WEBHOOK_SECRET in Heroku..."
heroku config:set STRIPE_WEBHOOK_SECRET="$webhook_secret" -a "${APP_NAME}"

echo ""
echo "==> Restarting application..."
heroku restart -a "${APP_NAME}"

echo ""
echo "✅ Webhook secret updated!"
echo ""
echo "==> Next steps:"
echo "1. Test the webhook from Stripe Dashboard:"
echo "   - Go to: https://dashboard.stripe.com/webhooks"
echo "   - Click your endpoint"
echo "   - Click 'Send test webhook'"
echo "   - Select: checkout.session.completed"
echo ""
echo "2. Check production logs:"
echo "   ./heroku/production/tail.sh --source app | grep StripeWebhook"
echo ""
echo "3. You should see:"
echo "   [StripeWebhook] Received event type=checkout.session.completed"
echo "   (No 'Invalid payload/signature' error)"
