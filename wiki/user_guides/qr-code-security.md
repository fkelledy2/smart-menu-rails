# QR Code Security — User Guide

## Overview

mellow.menu QR codes use rotating secure tokens instead of fixed web addresses, so scanning the physical code at your table is the only reliable way to access the menu and place orders. Each scan creates a short-lived dining session linked to that specific table. This protects your restaurant from fraudulent remote orders and makes it easy to invalidate a compromised code with a single click.

## Who This Is For

Restaurant owners and managers who manage table settings, and restaurant staff who handle QR code materials. Customers interact with this feature automatically every time they scan a QR code.

## Prerequisites

- You must have manager or owner access to the restaurant in mellow.menu.
- The `qr_security_v1` feature flag must be enabled for your restaurant. Contact mellow.menu support if you are unsure whether it is active.

## How To Use

### For Restaurant Owners and Managers

**Generating a QR code for a table**

1. From your restaurant dashboard, go to **Settings** > **Tables**.
2. Select the table you want a QR code for, or click **Add Table** to create one.
3. Click **Print QR Code**. The code encodes a secure, unique URL for that table.
4. Print or download the code and display it at the table.

**Regenerating a QR code (if a code is compromised or shared online)**

1. Go to **Settings** > **Tables**.
2. Find the affected table and click **Regenerate QR**.
3. Confirm the action. The old QR code stops working immediately for all customers currently using it.
4. Print and deploy the new QR code.

Note: any customer whose dining session was active on the old code will need to re-scan. This is intentional — it closes any open fraudulent sessions.

**Viewing active dining sessions (admin)**

Active sessions for your restaurant are visible in the admin panel. Contact mellow.menu support for access to session management tools.

### For Customers

1. Scan the QR code on your table with your phone camera.
2. The menu loads automatically. A dining session is created in the background — you do not need to do anything.
3. You can order freely during your visit. Your session stays active for up to 90 minutes, or 30 minutes after your last action, whichever comes first.
4. If your session expires mid-meal, you will see a prompt asking you to re-scan the QR code to continue.

## Key Concepts

**Public token** — the unique, random identifier encoded into each QR code URL. It looks like `/t/a3f9bc...` in the address bar. It cannot be guessed and is replaced entirely when you regenerate a code.

**Dining session** — a temporary record created when a customer scans a QR code. It ties together the customer's table, their order, and their browsing activity. Sessions expire automatically after inactivity or at a hard 90-minute limit.

**Token rotation** — the act of generating a new public token for a table. The physical QR code becomes invalid and must be reprinted.

## Tips & Best Practices

- Regenerate QR codes if you see orders from customers who are clearly not at the table (e.g., late-night orders when the restaurant is closed).
- Old `mellow.menu/smartmenus/...` links you may have shared in newsletters or social posts will still redirect customers to the correct menu. Only ordering requires a fresh QR scan.
- Print QR codes on durable materials (laminated table tents) to reduce wear and the need for frequent reprinting.
- For high-turnover venues, use the 30-minute inactivity timeout to your advantage — it means sessions from a previous sitting cannot carry over to the next.

## Limitations & Known Constraints

- Proximity verification (requiring customers to enter a short code printed on the table) is a future feature and is not yet available.
- Geo-based fraud detection (flagging orders from unexpected locations) is a future feature.
- A customer whose session expires must re-scan — there is no "resume session" link.
- Each table has one active QR code at a time. You cannot have multiple valid codes for the same table simultaneously.

## Frequently Asked Questions

**Q: Will existing printed menus and QR codes still work after I update the system?**
A: Old-format links (`/smartmenus/your-slug`) redirect automatically. Only ordering is locked to a fresh QR scan — browsing the menu still works.

**Q: What happens to customers mid-order if I regenerate the QR?**
A: Their sessions are invalidated. They will need to re-scan the new code. Any items already added to their order are not lost — they are associated with the session and will need to be re-added after the new scan creates a fresh session.

**Q: Can someone share the QR code link from their phone with a friend who is not at the table?**
A: Yes, but the dining session is bound to a specific QR scan. The rate limits on ordering per session and per IP make large-scale remote ordering impractical. Full proximity verification (a code printed on the table itself) is coming in a future release.

**Q: How do I know if my restaurant has QR security enabled?**
A: Go to **Settings** > **Tables**. If QR Security is active for your restaurant, a green "QR Security: Active" badge appears at the top of the Tables overview card. You can also check whether the QR codes you generate show a URL starting with `/t/` rather than `/smartmenus/`. Contact mellow.menu support to confirm or enable the `qr_security_v1` flag for your account.
