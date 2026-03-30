# Branded Receipt Emails — User Guide

## Overview

When a customer pays for their order through mellow.menu, staff can send a branded digital receipt to the customer's email address in just a few taps. Customers can also request their own receipt directly from the menu after paying. Every receipt carries your restaurant's name, logo, and an itemised breakdown of the order — giving customers a professional record of their purchase.

## Who This Is For

- **Restaurant staff and managers** who send receipts from the order management view.
- **Customers** who want to request a receipt from the menu after paying.

## Prerequisites

- The `receipt_email` feature flag must be enabled for your restaurant. Contact mellow.menu support to enable it.
- The order must be in "Paid" or "Closed" status before a receipt can be sent.
- Your restaurant's logo and name must be set in your restaurant profile for them to appear on receipts.

## How To Use

### For Staff — Sending a Receipt

1. Open the order in the staff order management view (kitchen dashboard or order detail page).
2. Confirm the order is in **Paid** or **Closed** status. The **Email Receipt** button only appears for completed orders.
3. Click **Email Receipt**.
4. In the modal that appears, enter the customer's email address. You can also enter an optional phone number if SMS delivery becomes available.
5. Click **Send**.
6. The receipt is queued for delivery. You will see a confirmation message. The customer typically receives the email within 60 seconds.

If delivery fails, the system automatically retries up to three times. If all retries fail, the receipt status shows as "Failed" in the order details.

### For Customers — Requesting Your Own Receipt

1. After your order is marked as paid, look for the **Get Receipt** option in the menu view on your phone.
2. Tap **Get Receipt**.
3. Enter your email address in the form that appears.
4. Tick the consent checkbox to confirm you agree to your email being used to send the receipt.
5. Tap **Send Receipt**.
6. Check your email — the receipt should arrive within 60 seconds.

## What Is Included in the Receipt

Each receipt email contains:

- Your restaurant's name and logo
- Restaurant address
- Order number
- Date and time of the order
- Itemised list of everything ordered, with individual prices
- Subtotal
- Tax amount
- Tip (if applicable)
- Grand total
- Last 4 digits of the payment card used (if available from the payment provider)
- A "Thank you" footer

Receipt emails are sent in HTML format with a matching plain-text version for email clients that do not render HTML.

## Key Concepts

**Receipt delivery record** — every receipt send attempt is logged. You can see whether a receipt was successfully delivered, is pending, or failed — this record is stored against the order.

**Self-service receipt** — the customer-facing receipt request form. Email addresses collected here are used only to send the receipt and are not added to any marketing list.

**SMS receipt** — a short-message receipt option is available as an optional add-on. It sends a brief message with a link to a web receipt page. Contact mellow.menu support to enable it (requires the `receipt_sms` flag).

## Tips & Best Practices

- Send receipts immediately after marking an order paid — customers expect a quick confirmation.
- If a customer asks for a receipt but you do not have their email address, ask them to use the **Get Receipt** option in the menu on their phone.
- For table-service restaurants, you can send the receipt while the customer is still at the table to confirm payment went through.
- Check the receipt delivery status on the order if a customer says they did not receive it — the system logs whether delivery succeeded.

## Limitations & Known Constraints

- PDF receipts are not available in v1. Receipts are sent as HTML emails only.
- Receipt templates cannot be customised per restaurant in v1. All receipts use the standard mellow.menu branded layout with your restaurant name and logo.
- Bulk resend (resending receipts for multiple orders at once) is not available.
- The receipt email shows up to the last 4 digits of the card. Full card numbers are never included.
- GDPR note: email addresses collected via the customer self-service form are used solely for delivering the receipt. They are not used for marketing without a separate explicit opt-in.

## See Also

- [Branded System Emails](/docs/user_guides/branded-system-emails.md) — overview of the shared branded email layout applied to all mellow.menu outgoing emails.

## Frequently Asked Questions

**Q: What if the customer says they did not receive the receipt?**
A: Open the order, scroll to the receipt delivery log, and check the status. If it shows "Failed", you can send a new receipt by clicking "Email Receipt" again and entering the email address. Also ask the customer to check their spam folder.

**Q: Can I send the receipt to a different email address than the one the customer originally provided?**
A: Yes. The "Email Receipt" modal lets you type any email address each time you send.

**Q: Can a receipt be sent more than once for the same order?**
A: Yes. Each send creates a new delivery record. There is no restriction on resending.

**Q: Who can see the email addresses collected via the receipt form?**
A: Only authorised staff and managers at your restaurant. Access is controlled by the platform's permission system.

**Q: Is the receipt feature available on all plans?**
A: The feature is enabled per restaurant via a feature flag. Contact mellow.menu support to confirm or enable it for your account.
