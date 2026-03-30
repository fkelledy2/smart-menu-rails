# Floorplan Dashboard — User Guide

## Overview

The Floorplan Dashboard gives restaurant staff a single-screen, real-time overview of every table in the venue. Each table tile shows its current status, how long the order has been open, how many guests are seated, and whether the bill has been requested or payment is pending. The screen updates automatically as orders progress — no refreshing required.

## Who This Is For

Restaurant staff and managers. Customers do not have access to this view.

## Prerequisites

- You must be logged in as a staff member or manager for the restaurant.
- The `floorplan_dashboard` Flipper feature flag must be enabled for your restaurant. Contact mellow.menu support to enable it.

## How To Use

**Opening the dashboard**

1. Sign in to your restaurant's staff interface.
2. In the restaurant sidebar, open the **Operations** section and click **Floorplan** (or navigate to `/restaurants/[your-restaurant-id]/floorplan`). The dashboard opens in a new tab.
3. The dashboard loads all your tables. Tables with active orders display live status information.

**Reading the table tiles**

Each tile on the dashboard shows:

| Element | What it means |
|---|---|
| Table name | The name or number you assigned in table settings |
| Status chip | The current order status, colour-coded (see below) |
| Time open | How long the current order has been active |
| Guest count | Number of participants linked to the order |
| Bill Requested badge | Appears when a customer has requested the bill |
| Payment status | Shows if payment is on file or auto-pay is armed (when Auto Pay is enabled) |

**Order status colours**

| Colour | Status | What it means |
|---|---|---|
| Green indicator (no chip) | Available | No active order — table is free |
| Grey | Opened | Order started but nothing ordered yet |
| Blue | Ordered | Items have been ordered |
| Orange | Preparing | Kitchen is working on the order |
| Green | Ready | Order is ready to be delivered |
| Muted green | Delivered | Order has been delivered to the table |
| Purple | Bill Requested | Customer has asked for the bill |
| Faded | Paid / Closed | Order is complete |

**Attention highlights**

A table tile is highlighted with a warning appearance when:

- The order has been in "Preparing" or "Ready" status for more than 15 minutes
- The order has been in "Bill Requested" status for more than 5 minutes

These thresholds are hardcoded in v1 and cannot be changed. They help you spot tables that may need attention before the customer becomes frustrated.

**Filtering the view**

Use the filter buttons at the top of the dashboard to narrow your focus:

- **All tables** — shows every table, including available ones
- **Active only** — hides tables with no current order
- **Bill requested** — shows only tables where the customer has asked for the bill
- **Delayed** — shows only tables that have triggered the attention threshold

Filters apply instantly without a page reload.

**Real-time updates**

You do not need to refresh the page. When any order changes status — for example, when a kitchen staff member marks an order ready — the relevant table tile updates automatically within a few seconds.

## Key Concepts

**Tablesetting** — the record in mellow.menu that represents a physical table in your restaurant. Tables must be created in **Settings** > **Tables** before they appear on the floorplan.

**Attention threshold** — the fixed time limit (15 minutes for preparing/ready, 5 minutes for bill requested) after which a table is highlighted to prompt staff action. These thresholds are hardcoded in v1 and cannot be configured per restaurant.

**Participant count** — the number of guests linked to the order, based on who has joined the dining session at that table.

## Tips & Best Practices

- Mount a tablet or dedicated screen at the host stand or pass with the Floorplan Dashboard open. It gives the whole team live situational awareness without verbal check-ins.
- Use the "Bill Requested" filter at busy times to quickly identify which tables need the bill run first.
- The "Delayed" filter is especially useful during peak service to catch orders that have fallen through the cracks in the kitchen.
- If a table shows as occupied when you know it is empty, check whether the previous order was properly closed in the order management view.

## Limitations & Known Constraints

- The Floorplan Dashboard is view-only in v1. You cannot take actions on orders directly from the tile (e.g., mark as ready or mark as delivered). Use the order management view for those actions.
- Custom drag-and-drop table layout (arranging tiles to match your physical floor plan) is not available in v1. Tables are displayed in an automatic grid sorted by name/number.
- Multiple rooms or floors are not supported in v1. All tables appear in a single unified view.
- If a table has more than one active order simultaneously (which should not normally happen), only the most recent order is shown, and a warning badge is displayed.

## Frequently Asked Questions

**Q: A table shows as occupied but the customer has left. How do I clear it?**
A: The table will clear automatically once the order is marked as Paid or Closed in the order management view. Open the order and move it to the correct status.

**Q: How often does the dashboard update?**
A: Updates arrive via a live connection and typically appear within 2 seconds of the order status changing. You do not need to refresh.

**Q: Can customers see the floorplan?**
A: No. The Floorplan Dashboard is only accessible to authenticated staff and managers.

**Q: How do I add more tables to the floorplan?**
A: Go to **Settings** > **Tables** and add or edit table settings. New tables appear on the floorplan immediately.

**Q: What does it mean when the time counter shows a very large number?**
A: This indicates an order has been open for an unusually long time. It may be a test order, an order that was not properly closed, or a genuine long dining session. Check the order detail to investigate.
