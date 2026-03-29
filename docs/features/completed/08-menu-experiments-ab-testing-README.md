# Menu A/B Experiments — User Guide

## What is this feature?

Menu A/B Experiments allows restaurant owners to test two versions of their menu simultaneously and measure the impact on customer ordering behaviour. Instead of making a blind change to the live menu, you can run a time-boxed experiment and see which version actually performs better before committing.

---

## Who can use this?

- **Plan requirement**: Pro or Business plan
- **Roles**: Restaurant owner, admin employees, manager employees
- **Feature flag**: `menu_experiments` must be enabled for your restaurant via the Flipper admin panel (`/flipper`)

---

## Getting started

### Step 1 — Create at least two menu versions

Before creating an experiment, you need two saved menu versions. Go to your menu's edit page and navigate to **Versions** in the sidebar. Create a snapshot of the current menu (this becomes your "control"). Make your proposed changes to the live menu, then create another snapshot (this is your "variant").

### Step 2 — Navigate to A/B Experiments

On the menu edit page sidebar, click **A/B Experiments**. This link is only visible when the `menu_experiments` Flipper flag is enabled for your restaurant.

The URL pattern is:
```
/restaurants/:restaurant_id/menus/:menu_id/experiments
```

### Step 3 — Create an experiment

Click **New experiment** and fill in:

| Field | Description |
|-------|-------------|
| Control version | The "safe" version — typically the current live menu |
| Variant version | The new version you want to test |
| Variant traffic allocation | What percentage of sessions should see the variant (1–99%). 50% is a balanced split. |
| Start time | Must be in the future |
| End time | When the experiment stops automatically |

**Important constraints:**
- Only one experiment can be active for a menu at a time
- The allocation percentage cannot be changed once the experiment is active
- Start time must be in the future when creating the experiment

### Step 4 — Monitor results

Click **Results** on any experiment to see:
- How many dining sessions were exposed to each version (control vs. variant)
- How many orders were placed by sessions in each group

> Note: Statistical significance is not automatically calculated in v1. Review the exposure and order counts manually to judge whether the variant is performing better.

---

## Experiment lifecycle

| Status | Meaning | Actions available |
|--------|---------|-------------------|
| **Draft** | Created but not yet running | Edit, Delete |
| **Active** | Currently running — customers are being assigned | Pause, End |
| **Paused** | Temporarily stopped | End |
| **Ended** | Experiment is over | View results only |

- **Pause**: Stops new assignment but does not clear existing session assignments
- **End**: Permanently ends the experiment. All customers return to the default active menu version immediately
- **Delete**: Only available for draft experiments

---

## How assignment works

When a customer scans the QR code and starts a dining session:
1. The system checks if a `menu_experiments` flag is enabled for the restaurant
2. If an active experiment exists for the menu, the customer's session token is hashed and mapped to a 0–99 bucket
3. If the bucket falls below the allocation percentage, the customer sees the **variant**; otherwise they see the **control**
4. The assignment is stored on the session — refreshing the page or ordering won't change which version they see

Assignment is deterministic: the same session token always maps to the same version for the same experiment.

---

## What happens when an experiment ends?

- At or after the `End time`, all customers see the default active menu version
- The `EndExpiredMenuExperimentsJob` (runs every 15 minutes) sets the experiment status to `ended` as a housekeeping step
- The serve-time logic checks the experiment's `ends_at` directly — there is no gap in protection

---

## How to promote a winning variant

After the experiment ends, if the variant performed better:
1. Go to the **Versions** tab on the menu edit page
2. Find the variant version
3. Click **Activate/Schedule** to make it the new active version

---

## Feature flag management

The flag `menu_experiments` must be enabled per restaurant. To enable it:
1. Go to `/flipper` (admin access required)
2. Find `menu_experiments`
3. Enable it for a specific actor: `Restaurant;{id}` where `{id}` is the restaurant ID

---

## Out of scope in v1

- Multi-variant testing (more than 2 versions)
- Automatic winner promotion
- Statistical significance reporting
- AI-suggested variant content
