# Auto Pay & Leave — User Guide

## Overview

Auto Pay & Leave lets customers add a payment card during their meal and enable automatic charging when it is time to pay. Instead of waiting for staff to bring the bill and process a payment, the charge happens automatically the moment the restaurant marks the order ready. Staff retain full visibility and control throughout — they can disable auto-pay or override it at any time.

## Who This Is For

- **Customers** who want to pay and leave without waiting for the bill.
- **Restaurant staff and managers** who monitor table payment status and handle payment exceptions.

## Prerequisites

- The `auto_pay` Flipper feature flag must be enabled for your restaurant. This is an opt-in setting — contact mellow.menu support to enable it.
- Payments must be processed through Stripe. Square support is not available in v1.
- Customers must have scanned the QR code and have an active dining session.

## How To Use

### For Customers

**Step 1 — Add your payment card**

1. After you have started an order, tap **Add Payment Method** in the order view on your phone.
2. A secure card entry form loads. Enter your card details. Your card number never passes through the restaurant's or mellow.menu's servers — it goes directly to the payment provider.
3. Once saved, you will see a confirmation that a payment method is on file.

**Step 2 — View your bill**

1. Tap **View Bill** in the order view. You will see an itemised summary of everything ordered, any applicable tax, and tip options.
2. Select a tip amount if you wish to add one.
3. Review the total.

**Step 3 — Enable auto-pay**

1. Tap the **Enable Auto-Pay** toggle.
2. A confirmation dialog explains exactly when you will be charged — you will be asked to agree before the toggle activates.
3. Once confirmed, auto-pay is armed. You will see an "Auto-Pay Armed" indicator on your order view.

**What happens next**

When the restaurant marks your order as ready to charge (or your order status changes to bill requested), the payment is processed automatically. You will receive a confirmation on screen. You are free to leave — no waiting for a card machine or staff.

**Cancelling auto-pay before it fires**

Tap the **Auto-Pay** toggle again at any time before the charge occurs to turn it off. You can then pay manually via staff.

**Important: total changes after arming**

If your order total changes after you enable auto-pay (for example, if an item is comped or a discount is applied), auto-pay is automatically disarmed and you will need to review the new total and re-enable it. This protects you from being charged an amount you did not consent to.

---

### For Restaurant Staff

**Understanding the payment badges**

On the order header in the staff view, three badges indicate a table's payment readiness:

| Badge | Meaning |
|---|---|
| Payment on File | Customer has a card stored |
| Bill Viewed | Customer has opened and reviewed their bill |
| Auto-Pay Armed | Customer has consented and auto-pay is active |

**Disabling auto-pay for a table**

1. Open the order in the staff order management view.
2. Click **Disable Auto-Pay**.
3. Auto-pay is turned off. The order remains open for manual handling (comp, dispute, cash payment, etc.).

**Manually charging a table**

Even if auto-pay is not enabled, you can charge a table that has a card on file:

1. Open the order in the staff view.
2. Click **Charge Now**.
3. The charge is processed immediately via the stored payment method.

**What happens on a successful auto-pay charge**

- The order status moves to "Paid".
- A receipt is sent automatically if the receipt email feature is enabled for your restaurant.
- A success notification appears in the staff interface in real time.

**What happens if a charge fails**

- The order remains open.
- A failure notification appears in the staff interface with a non-sensitive reason (e.g. "Card declined").
- You can attempt a manual charge or handle the payment through other means.

## Key Concepts

**Payment method** — a tokenised reference to the customer's card, managed by Stripe. No raw card data is stored by mellow.menu.

**Auto-pay consent** — the customer's explicit agreement (with a timestamp) to be charged when the restaurant triggers billing. Consent is required before auto-pay can fire.

**Bill requested** — an order status that triggers auto-pay capture when set. Staff can move an order to this status, or it can transition automatically depending on your restaurant's workflow settings.

**Idempotent capture** — the system prevents a card from being charged twice for the same order, even if something causes the payment job to run more than once.

## Tips & Best Practices

- Mention the Auto Pay option to customers early in the meal — it works best when they add their card while relaxed, not when they are in a hurry to leave.
- Use the **Bill Viewed** badge as a signal that a customer is ready to pay, even if they have not enabled auto-pay.
- If a customer wants to split the bill, they should each add their own card and pay their share individually. Full split-by-item functionality is a future feature.
- The **Charge Now** button is useful for restaurants that prefer to initiate payment from the staff side even when auto-pay is armed early.

## Limitations & Known Constraints

- Auto-pay requires Stripe. Square payment processing is not supported in v1.
- Tip amounts cannot be adjusted after a charge has been captured.
- Granular bill splitting (each person pays for specific items) is not available in v1. Each participant can pay their own total.
- Auto-pay only processes charges online. Offline or cash fallback is not automated.
- Forced charging without customer consent is not possible — a card on file alone is not sufficient to charge; the customer must enable auto-pay or staff must use the Charge Now action.

## Frequently Asked Questions

**Q: Can a customer be charged without enabling auto-pay?**
A: Only if staff click "Charge Now" manually, using the stored payment method. Auto-pay will never fire unless the customer explicitly enables it and provides consent.

**Q: What if the customer leaves before paying?**
A: If auto-pay was armed and the charge succeeded, the order is closed. If the payment failed or was never initiated, the order stays open for manual resolution — the same as any unpaid order today.

**Q: Is it safe to store a card on file?**
A: Yes. Card details are handled entirely by Stripe. mellow.menu only stores a token reference — never the actual card number, expiry, or security code.

**Q: Can the customer remove their card from the order?**
A: Yes. Before a charge is captured, the customer can tap to remove their payment method from the order.

**Q: How do I enable Auto Pay & Leave for my restaurant?**
A: Contact mellow.menu support to enable the `auto_pay` feature flag for your account.
