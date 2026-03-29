# Employee Order Notes — User Guide

## Overview

Employee Order Notes lets restaurant staff attach internal notes to any order — from allergy warnings and cooking preferences to timing instructions and special occasion reminders. Notes appear instantly for all staff across the kitchen and service team, sorted by priority. Urgent dietary notes pulse with a visual alert to ensure they are never missed.

## Who This Is For

All restaurant staff: servers, kitchen staff, and managers. Each role has slightly different permissions (see below). Customers can see notes only when a staff member explicitly marks a note as customer-visible.

## Prerequisites

- You must be logged in as a staff member, manager, or admin for the restaurant.
- No feature flag is required — this feature is available to all restaurants.

## How To Use

### Adding a Note to an Order

1. Open the order in the staff order view.
2. Scroll to the **Order Notes & Instructions** section.
3. Click **Add Note**.
4. In the modal that appears, fill in the following:

   **Category** — choose the type of note:
   - Dietary Restrictions — use this for allergies and dietary requirements
   - Preparation Instructions — cooking preferences, ingredient modifications, plating
   - Timing Instructions — rush orders, delayed preparation, coordination
   - Customer Service — special occasions, VIP notes, complaint resolution
   - Operational Notes — staff coordination, equipment, inventory

   **Priority** — choose how urgently the note needs to be seen:
   - Low, Medium, High, or Urgent

   **Note content** — type the note (3–500 characters).

   **Visibility** — tick who should see the note:
   - Kitchen (ticked by default)
   - Servers (ticked by default)
   - Customers (unticked by default — only tick this if the note is appropriate for the customer to see)

   **Expiration** (optional) — set a date and time for the note to expire automatically. Useful for time-sensitive instructions.

5. Click **Add Note**.

The note appears at the top of the notes list, ordered by priority. All staff viewing that order see it immediately — no page refresh needed.

### Using Quick Templates

For common scenarios, click one of the quick templates in the Add Note modal to pre-fill the category, priority, and a starter text:

- **Severe Allergy Alert** — pre-fills dietary category, urgent priority
- **Rush Order** — pre-fills timing category, high priority
- **Birthday Celebration** — pre-fills customer service category, medium priority
- **Cooking Preference** — pre-fills preparation category, medium priority

Customise the content as needed after selecting a template.

### Editing a Note

1. Find the note card on the order.
2. Click the pencil (edit) icon.
3. Modify the content, category, priority, or visibility.
4. Click **Update Note**.

**Permission rules for editing:**
- You can edit your own notes within 15 minutes of creating them.
- Managers and admins can edit any note at any time.

### Deleting a Note

Click the delete icon on the note card. The same permission rules apply as for editing.

### Viewing Notes as Kitchen Staff

Urgent and high-priority notes are shown at the top of the list with a coloured border:

- Red border with a pulsing animation — Urgent
- Thick red border — High
- Standard border — Medium or Low

The colours also indicate category:

| Category | Colour |
|---|---|
| Dietary Restrictions | Red |
| Preparation Instructions | Blue |
| Timing Instructions | Yellow |
| Customer Service | Green |
| Operational | Grey |

### Customer-Visible Notes

If a note is marked visible to customers, it appears in the customer's order view on their phone (for example: "Your steak will be cooked well-done as requested"). Use this sparingly and only for notes that are reassuring or informative for the customer.

## Key Concepts

**Active notes** — notes that have not expired. Expired notes are hidden from the main view but remain in the order record for audit purposes.

**Edit window** — the 15-minute period after creating a note during which the author can edit or delete it. After this window, only managers and admins can make changes.

**Visibility flags** — the three checkboxes (Kitchen, Servers, Customers) that control which audience sees each note.

## Tips & Best Practices

- Always use the Dietary Restrictions category with Urgent priority for allergy notes. The visual alert is designed to catch kitchen staff's attention immediately.
- Use the expiration field for timing notes (e.g., "Hold dessert until 8 pm") so the instruction disappears automatically once it is no longer relevant.
- Keep customer-visible notes brief and positive — they appear in the customer's order view, which should feel reassuring, not alarming.
- Use the Operational category for kitchen-to-front-of-house messages, such as equipment issues that affect service timing.
- Managers should periodically review dietary notes on active orders during peak service as a quality control step.

## Limitations & Known Constraints

- Notes are order-level, not item-level. For per-item customer requests (e.g., "no onions on the burger"), customers add those directly when placing the order in the menu.
- Note content cannot exceed 500 characters.
- Photo attachments are not supported in v1.
- Voice-to-text note input is not yet available.
- Once a note's 15-minute edit window closes, only managers and admins can modify or delete it.

## Frequently Asked Questions

**Q: Can customers see all the notes staff have written?**
A: No. Only notes explicitly marked "Customers" visible are shown to the customer. By default, new notes are only visible to kitchen and server staff.

**Q: What happens to a note after it expires?**
A: The note is hidden from the active notes list but is not deleted. It remains attached to the order for historical reference.

**Q: I cannot see the edit button on a note I wrote. Why?**
A: The edit button only appears within 15 minutes of creation. If that window has passed, you will need a manager or admin to edit the note.

**Q: Do notes update in real time for kitchen screens?**
A: Yes. When a note is added, edited, or deleted, it updates immediately on all staff devices viewing that order — no page refresh required.

**Q: Can I search or filter notes across multiple orders?**
A: Filtering within a single order by category and priority is built in (notes are sorted by priority automatically). Cross-order note reporting is available to managers via the analytics tools.
