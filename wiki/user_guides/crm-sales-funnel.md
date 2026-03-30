# CRM Sales Funnel — User Guide

## Overview

The CRM Sales Funnel is an internal tool for the mellow.menu sales team to track restaurant prospects from first contact through to becoming a paying customer. Leads move through a visual Kanban board and advance automatically when key events happen — like a prospect booking a demo via Calendly. Sales reps can log notes, send follow-up emails, and link converted leads directly to their restaurant record, all in one place.

## Who This Is For

mellow.menu internal staff only — sales representatives, sales managers, and platform admins. Restaurant owners and their staff cannot access the CRM.

## Prerequisites

- You must be signed in with a mellow.menu admin account.
- The `crm_sales_funnel` Flipper feature flag must be enabled. Contact your platform admin to enable it.
- Calendly webhook integration must be configured to enable automatic demo booking transitions (this is a one-time setup by a platform engineer).

## How To Use

### Viewing the Kanban Board

1. In the admin navigation, go to **CRM** > **Leads**.
2. The Kanban board displays all leads grouped into stage columns from left to right:
   - New → Contacted → Demo Booked → Demo Completed → Proposal Sent → Trial Active → Converted → Lost

3. Each card shows the restaurant name, contact name, last activity date, and the assigned sales rep's avatar.
4. Use the **Needs Assignment** filter to see leads that arrived via Calendly without a rep assigned.

### Creating a Lead Manually

1. Click **New Lead** (top right of the Kanban board).
2. Fill in:
   - Restaurant name (required)
   - Contact name
   - Contact email
   - Contact phone (optional)
   - Source (e.g., manual, referral)
3. Assign a sales rep from the **Assigned to** dropdown (optional — can be assigned later).
4. Click **Create Lead**.

The lead appears in the **New** column.

### Moving a Lead to a New Stage

**By dragging:**
1. Click and hold a lead card.
2. Drag it to the target stage column.
3. Release. The stage updates immediately.

**From the lead detail panel:**
1. Click on a lead card to open the detail panel.
2. Use the stage transition buttons to move the lead forward.

Some transitions have requirements:
- Moving to **Converted** requires a restaurant record to be linked first (see Marking a Lead as Converted below).
- Moving to **Lost** requires a reason to be selected.
- Lost leads can be moved back to **Contacted** to reopen them (the only backward transition allowed).

### Viewing and Adding Notes

1. Click on a lead card to open the detail panel.
2. Click the **Notes** tab.
3. Read any existing notes in chronological order.
4. Type a new note in the compose box and click **Add Note**.

Notes are visible to all admin team members. They are intended for internal context — call summaries, objections raised, follow-up reminders.

### Sending a Follow-Up Email

1. Open the lead detail panel.
2. Click the **Email** tab.
3. The "To" field is pre-filled with the lead's contact email.
4. Enter a subject and compose your message.
5. Click **Send**.

The email is sent using the mellow.menu branded layout. A copy is logged in the lead's activity timeline.

### Viewing the Activity Log

1. Open the lead detail panel.
2. Click the **Activity** tab.
3. The full history of changes is shown: every stage transition, field update, note, and email — including changes made automatically by the system (e.g., "Stage advanced to Demo Booked via Calendly webhook").

The activity log is read-only. Records are permanent — entries cannot be edited or deleted.

### Marking a Lead as Converted

When a prospect becomes a customer:

1. Open the lead detail panel.
2. Click **Mark as Converted**.
3. In the modal, search for or select the corresponding restaurant record in mellow.menu.
4. Confirm. The lead moves to the **Converted** stage and is linked to the restaurant.

Once converted, you can navigate directly from the lead to the live restaurant record.

### Handling Automatic Calendly Transitions

When a prospect books a demo via the mellow.menu Calendly link:

- If a lead already exists with that email address, the system automatically moves it to **Demo Booked**.
- If no lead exists yet, the system creates a new one with the source set to "Calendly" and no assigned rep. These appear in the **Needs Assignment** filter.

No manual action is needed. The activity log records the transition as a system event.

## Key Concepts

**Stage** — the current position of a lead in the sales pipeline. Stages move forward (with one exception — Lost leads can reopen to Contacted).

**Activity log** — an immutable, tamper-evident record of everything that has happened to a lead: who changed what, when, and why. System events (Calendly, automatic transitions) are recorded alongside manual actions.

**Calendly event UUID** — the unique identifier from a Calendly webhook that prevents the same booking from advancing a lead twice.

**Conversion** — the act of linking a lead to an active restaurant record in mellow.menu and moving it to the Converted stage. This creates an audit trail from the first sales contact to the live customer.

## Tips & Best Practices

- Process the **Needs Assignment** queue at the start of each working day so inbound Calendly leads get a rep quickly.
- Log a note after every call or meeting — even a brief summary. The activity log is the shared memory of the team.
- Use the **Proposal Sent** stage only when an actual proposal document has been sent, not when a verbal offer has been made. This keeps pipeline reporting accurate.
- When a deal is lost, choose the most accurate reason from the dropdown. This data helps the team understand patterns in why deals fail.
- Link converted leads to restaurant records on the same day the restaurant goes live — it ensures the sales-to-product handoff is traceable.

## Limitations & Known Constraints

- The CRM is for internal mellow.menu use only. Restaurant owners cannot see or access it.
- Email replies from prospects are not tracked in v1. The CRM records outbound sends only. Check your email client for replies.
- The Kanban board does not update in real time for multiple simultaneous users. If two reps are working on the board at the same time, one may need to refresh to see the other's changes.
- Lead deduplication is not automated. If the same prospect books via Calendly under two different email addresses, two separate leads will be created.
- Bulk import of leads from CSV is not available in v1.
- Revenue forecasting and pipeline value calculations are not available.

## Frequently Asked Questions

**Q: A Calendly booking came in but the lead was not created. What happened?**
A: Check that the Calendly webhook is configured and that the webhook secret is current. Contact your platform engineer if the integration appears to have stopped working.

**Q: Can I re-assign a lead to a different sales rep?**
A: Yes. Open the lead detail panel and change the **Assigned to** field. The change is logged in the activity timeline.

**Q: A lead was accidentally moved to the wrong stage. Can I move it back?**
A: Forward stages can be corrected by moving the card to the correct column. The only restricted backward transition is that only **Lost** leads can move back (to Contacted). If a lead has been incorrectly moved far forward in the pipeline, drag it back to the correct stage manually.

**Q: How do I mark a lead as lost?**
A: Drag the card to the **Lost** column. A prompt will ask you to select a reason. Choose the most appropriate option and confirm.

**Q: Who can see the contact email addresses stored in the CRM?**
A: Only mellow.menu admin accounts. Contact data in the CRM is subject to GDPR data handling requirements — contact details should be used only for legitimate sales follow-up.
