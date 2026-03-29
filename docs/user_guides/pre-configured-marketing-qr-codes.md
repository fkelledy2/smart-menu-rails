# Pre-Configured Marketing QR Codes — User Guide

## Overview

Pre-configured marketing QR codes let the mellow.menu team generate and distribute printed materials — table tents, window stickers, flyers — before a restaurant's menu is fully set up. The QR code's physical URL never changes, so print runs happen early without risk of reprinting. Before the restaurant is ready, scanning the code shows a professional "Coming Soon" page. Once the restaurant goes live, the code is linked to the correct menu and scanning takes customers straight to their table's menu.

## Who This Is For

This feature is for mellow.menu internal staff (accounts with a `@mellow.menu` email address) only. Restaurant owners and their staff cannot create or manage marketing QR codes.

## Prerequisites

- You must be signed in with a `@mellow.menu` account with admin privileges.
- To link a code to a restaurant, that restaurant must already exist in the system.

## How To Use

### Creating a New Marketing QR Code

1. In the admin navigation, go to **Marketing QR Codes** (under the Admin section).
2. Click **New Marketing QR Code**.
3. Fill in:
   - **Name** — a human-readable label for internal tracking (e.g., "Dublin launch — Table 1–10 batch")
   - **Campaign** — an optional tag to group codes by campaign (e.g., "Q1 2026 restaurant onboarding")
   - **Holding URL** (optional) — a URL to redirect unlinked scans to. Defaults to the mellow.menu branded "Coming Soon" page if left blank.
4. Click **Create**.

The system generates a unique, permanent token for the code. The encoded URL (in the format `https://mellow.menu/m/[token]`) is displayed and ready to use in print materials.

### Generating the Printable QR

1. On the marketing QR code detail page, click **Print / Download**.
2. A print-optimised page opens showing the QR code and the encoded URL.
3. Print or save as PDF for your print supplier.

### Linking a Code to a Restaurant

Once the restaurant is configured in mellow.menu, link the code so scans go to the live menu:

1. In **Marketing QR Codes**, find the code you want to link (filter by campaign or search by name).
2. Click **Link**.
3. In the linking form:
   - Select the **Restaurant**
   - Optionally select a specific **Menu** (if the restaurant has more than one)
   - Optionally select a specific **Table** (if the code is for a specific table)
4. Click **Confirm Link**.

The code is now live. Customers who scan it are redirected immediately to the correct Smartmenu for that restaurant and table.

If the restaurant does not yet have a Smartmenu for the selected combination, the system creates one automatically.

### Unlinking a Code

To revert a linked code back to the "Coming Soon" holding state:

1. Open the marketing QR code.
2. Click **Unlink**.
3. Confirm the action.

Scans now show the holding page again. The physical QR code is unchanged and can be re-linked at any time.

### Checking Scan Status

Each marketing QR code shows a status badge:

| Status | Meaning |
|---|---|
| Unlinked | Scans go to the holding page |
| Linked | Scans redirect to the live Smartmenu |
| Archived | Code is retired and no longer in use |

## Key Concepts

**Permanent token** — the unique identifier built into the QR code URL. It never changes, so the printed QR code remains valid indefinitely. Only the destination it resolves to can change.

**Holding page** — the branded page shown to customers who scan an unlinked code. It communicates that the restaurant is "coming soon" without showing a broken link or an error.

**Linking** — the act of connecting a marketing QR code to a specific restaurant, menu, and optionally a table. Once linked, scans bypass the holding page and go straight to the Smartmenu.

**Campaign** — an optional grouping label you can use to organise batches of codes by launch wave, geography, or sales campaign.

## Tips & Best Practices

- Generate and print QR codes in batches during the sales process, before restaurant onboarding is complete. This allows print materials to be ready on or before launch day.
- Use the Campaign field to group codes by restaurant cluster or onboarding cohort — it makes finding the right code faster when it is time to link.
- Keep the Holding URL pointing to the mellow.menu homepage or a dedicated "restaurants launching soon" landing page for a professional customer experience.
- Link codes as the final step in onboarding, immediately after confirming the Smartmenu is working correctly.
- Archive codes that are no longer in use rather than deleting them, so the audit trail is preserved.

## Limitations & Known Constraints

- Only `@mellow.menu` staff can create, link, and manage marketing QR codes. Restaurant owners cannot self-serve this process in v1.
- Bulk QR code generation (creating many codes at once via CSV) is not available in v1.
- Campaign analytics (tracking how many times each code has been scanned) are not available in v1.
- Integration with print-on-demand services is not supported.
- Each code can only be linked to one restaurant/menu/table combination at a time.

## Frequently Asked Questions

**Q: What do customers see if they scan the code before it is linked?**
A: They see a professional branded "Coming Soon" page (or the custom URL you specified in the Holding URL field). They will not see an error or broken link.

**Q: Can the physical QR code ever change?**
A: No. The token encoded in the QR code is permanent. What changes is the destination it redirects to — controlled by the link status in the admin panel.

**Q: A restaurant's setup changed after we linked the code (e.g., they got a new table layout). Do we need to reprint the QRs?**
A: If the Smartmenu the code was linked to still exists, no reprint is needed — the code still resolves to that Smartmenu. If the table configuration was deleted and a new one created, you may need to re-link the code to the new table setting.

**Q: How do I find a code if I do not remember its name?**
A: Use the Campaign filter on the Marketing QR Codes list page to find codes by campaign group, or search by restaurant name once the code has been linked.

**Q: Can I link the same code to a different restaurant later?**
A: Yes. Unlink it first, then use the Link action to connect it to the new restaurant.
