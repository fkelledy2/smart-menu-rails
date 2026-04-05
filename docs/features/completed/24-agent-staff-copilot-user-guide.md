# Staff Copilot — User Guide

Feature reference: #24  
Shipped: 2026-04-05

---

## What is the Staff Copilot?

The Staff Copilot is a natural-language back-office assistant that lets restaurant managers and staff get information and take quick actions without navigating through multiple screens. Type a question or command in plain English, and the Copilot responds instantly.

---

## Enabling the Feature

The Staff Copilot requires two Flipper feature flags to be enabled for your restaurant:

1. `agent_framework` — the shared agent infrastructure
2. `agent_staff_copilot` — the Staff Copilot specifically

To enable for a specific restaurant, an admin can run:

```ruby
restaurant = Restaurant.find(<id>)
Flipper.enable(:agent_framework, restaurant)
Flipper.enable(:agent_staff_copilot, restaurant)
```

Or enable globally for all restaurants:

```ruby
Flipper.enable(:agent_framework)
Flipper.enable(:agent_staff_copilot)
```

Once enabled, a floating Copilot button appears in the bottom-right corner of all back-office pages for that restaurant.

---

## Who Can Use It?

The Copilot is available to:

- Restaurant **owners**
- Active **employees** (staff, manager, or admin role) of the restaurant
- **Super admins**

Users who are not affiliated with the restaurant are denied access.

---

## Using the Copilot Panel

### Opening the Panel

Click the floating Copilot button (bottom-right corner of any back-office page). The panel slides open.

### Asking a Question

Type your question or command in the input box and press **Send** (or `Cmd+Enter` / `Ctrl+Enter`). The Copilot responds within a few seconds.

### Keyboard Shortcut

- `Cmd+Enter` (Mac) or `Ctrl+Enter` (Windows/Linux) — submit your query

### Closing the Panel

Click the Copilot button again or the X icon in the panel header.

---

## What You Can Ask

### Analytics Queries

Get quick revenue and order stats without opening the full analytics dashboard:

> "Show me today's sales"  
> "What were our top 5 items this week?"  
> "How much revenue did we make last month?"  
> "How's our average ticket this week compared to last week?"

The Copilot returns:
- Total orders and revenue
- Average ticket size
- Top-selling items by quantity
- The time period it analysed

### Item Availability

Instantly mark items as unavailable (86'd) or bring them back:

> "86 the burrata"  
> "Mark the lobster roll as unavailable"  
> "Bring back the chicken sandwich"

The Copilot identifies the item and presents a confirmation card before making any change. Review the details, then click **Confirm** to apply.

### Creating New Menu Items

Add a new item to your menu through conversation:

> "Add a new dessert called Lemon Tart at €8.50"  
> "Create a vegan main — Beyond Burger, $14, on the Mains section"

The Copilot fills in the details and shows you a confirmation card with the item name, price, and section. Confirm to save.

### Editing Existing Items

Update an item's name, price, or description:

> "Change the price of the house salad to $12"  
> "Rename 'Chips' to 'Hand-Cut Fries'"  
> "Update the Caesar salad description to mention it contains anchovies"

### Drafting Staff Messages

Generate a professional team briefing draft:

> "Write a staff briefing about our new cocktail menu launching Friday"  
> "Draft a message for the team about the private event on Saturday"

The Copilot produces a subject line and body for your review. You can then send it (the `send_staff_message` confirm action) to your team via email.

---

## Understanding Responses

### Narrative Response

A plain text answer — for analytics results, explanations, and informational queries. No action is required.

### Action Card

A proposed change that needs your confirmation before it's executed. Review the details shown (item name, price, section, etc.) and click:

- **Confirm** — applies the change immediately
- **Cancel** — discards the action

### Disambiguation

When the Copilot finds multiple matching items (e.g., "burger" matches "Beef Burger" and "Chicken Burger"), it asks you to choose. Select the correct item and the action proceeds.

### Error Response

If the Copilot cannot process your query (e.g., it doesn't understand the intent, or an API error occurred), it returns a friendly message explaining what went wrong.

---

## Conversation Context

The Copilot remembers the last 5 exchanges in your current session. This lets you ask follow-up questions naturally:

> "Show me this week's sales"  
> *(Copilot responds)*  
> "What about the same period last month?"

---

## Rate Limiting

To prevent abuse, each user is limited to **30 queries per hour**. If you exceed this, the Copilot will notify you and you can retry after the hour window resets.

---

## Page Context

When you open the Copilot from a specific back-office page (e.g., the Menu editor or Analytics dashboard), it automatically receives the page context. This allows more relevant default behaviour — for example, asking about an item while on the menu page can pre-populate the menu section.

---

## Confirm Actions — Write Operations

All write operations (item availability changes, new items, edits, staff messages) go through a confirmation step. The Copilot never modifies your data without an explicit confirmation click. This is intentional — treat the Copilot as a smart assistant that proposes changes, not one that executes them automatically.

---

## Security and Permissions

- All actions are gated by the same Pundit policy that governs the rest of the back-office.
- Write actions are constrained to the `ALLOWED_TOOLS` allowlist in `Agents::StaffCopilotConfirmService`.
- Tool calls are parameterised — no raw SQL or shell commands are possible.
- A secondary RackAttack throttle limits Copilot endpoints to 60 requests per 10 minutes per IP.

---

## Known Limitations

- Analytics data covers standard order periods (today, yesterday, this week, last week, this month, last month). Custom date ranges are not yet supported.
- Staff messages are drafted but emailed via the `CopilotBriefingMailer` — a full in-app messaging UI is planned for a future iteration.
- Item availability changes apply globally across all menus and sections for that item.
- The Copilot does not currently support multi-location queries (i.e., comparing stats across two restaurants in one query).

---

## Troubleshooting

**The Copilot button doesn't appear**  
Both `agent_framework` and `agent_staff_copilot` flags must be enabled for your restaurant. Contact your administrator.

**I get "Feature not available" when I try to query**  
One or both feature flags may have been disabled. Contact your administrator.

**The Copilot misidentifies the item I asked about**  
Use the item's full name as it appears in the menu. If multiple items match, the disambiguation flow will prompt you to select the correct one.

**Queries are slow**  
The Copilot calls OpenAI's API for intent classification. Occasional latency is expected. If slowness persists, check Sidekiq and the OpenAI service status.
