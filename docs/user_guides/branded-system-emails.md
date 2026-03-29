# Branded System Emails — User Guide

## Overview

All emails sent by mellow.menu — from account confirmation and password resets to order receipts and onboarding reminders — use a consistent branded layout. Every email carries the mellow.menu logo, brand colours, and professional typography, and includes a footer with support links. You do not need to configure anything for this to work — it is applied automatically to all outgoing email.

## Who This Is For

- **Restaurant owners and staff** who receive system emails during sign-up, onboarding, and daily operations.
- **Customers** who receive order receipts and other transactional notifications.

## Prerequisites

None. Branded email styling is applied automatically to all mellow.menu accounts. No feature flag or configuration is required.

## What the Branded Emails Look Like

Every mellow.menu system email includes:

- The mellow.menu logo in the header
- Consistent colour palette matching the mellow.menu brand
- Clear, readable body text (minimum 16px font size)
- A footer with:
  - A link to the mellow.menu website
  - A support contact link
  - An unsubscribe or privacy link where required

The layout is single-column and responsive, so it reads well on both desktop email clients and mobile phones.

## Email Types That Use the Branded Layout

| Email | When it is sent |
|---|---|
| Email confirmation | When you register a new account |
| Password reset | When you request a password reset |
| Welcome email | Shortly after your account is confirmed |
| Order receipt | After a customer pays (when receipt email is enabled) |
| Onboarding reminder | If setup steps are incomplete |
| Demo booking confirmation | After a prospective customer books a demo |
| JWT token delivery | When an API token is sent to a partner |

## Key Concepts

**Branded mailer layout** — the shared template that wraps the content of every email. It ensures consistency across all email types without requiring each email to be individually styled.

**Plain-text version** — every email also includes a plain-text alternative for email clients that do not display HTML. The text version contains all the same information in a readable format.

## Tips & Best Practices

- If a customer or staff member says they are not receiving mellow.menu emails, ask them to check their spam folder. Emails come from `hello@mellow.menu`.
- The unsubscribe or opt-out link in the footer is for transactional safety compliance — clicking it may affect which system emails you receive. Do not use it to avoid important account notifications.

## Limitations & Known Constraints

- Per-restaurant email branding (using your restaurant's own logo and colours in system emails) is not available in v1. All emails use the mellow.menu platform brand.
- Email analytics (open rates, click tracking) are not available.
- Marketing email sequences are not available via this system.

## Frequently Asked Questions

**Q: Can I use my restaurant's logo in emails sent to my customers?**
A: Not in v1. System emails use the mellow.menu brand. The exception is the order receipt email, which does display your restaurant's name and logo in the receipt body. Per-restaurant email branding across all email types is a planned future feature.

**Q: Why is my email going to spam?**
A: Check that the email address you registered with is valid and that your email provider is not filtering messages from `mellow.menu`. Add `hello@mellow.menu` to your contacts to help your spam filter recognise legitimate messages.

**Q: I never received my account confirmation email. What should I do?**
A: Check your spam folder first. If it is not there, return to the sign-in page and use the "Resend confirmation" option, or contact mellow.menu support.
