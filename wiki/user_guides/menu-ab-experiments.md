# Menu A/B Experiments — User Guide

## Overview

Menu A/B Experiments lets you test two versions of your menu at the same time to see which one performs better before committing to a change. You set a split percentage, a start and end time, and let the system run. Each customer who scans the QR code is automatically and consistently assigned to one version for their entire visit. After the experiment ends, you can compare how many orders each version generated and decide which one to keep.

## Who This Is For

Restaurant owners and managers who want to make data-informed decisions about menu changes — pricing adjustments, new item descriptions, section reordering, or other edits.

## Prerequisites

- The `menu_experiments` Flipper feature flag must be enabled for your restaurant. Contact mellow.menu support to request access.
- Your menu must have at least two saved versions before you can create an experiment. See the Menu Versioning guide if you have not created versions yet.
- This feature is available on Pro and Business plans.

## How To Use

### Step 1 — Create Menu Versions to Test

Before setting up an experiment, you need two saved snapshots of your menu:

1. Go to your menu's edit page.
2. Open the **Versions** tab in the sidebar.
3. Your current live menu can be saved as the "control" version — click **Save current version** and name it clearly (e.g., "Control — March 2026").
4. Make the changes you want to test (e.g., update a description or adjust a price).
5. Save this changed state as another version — name it clearly (e.g., "Variant — updated burger prices").

You now have two versions to experiment with.

### Step 2 — Open the Experiments Panel

1. On the menu edit page, click **A/B Experiments** in the sidebar.
2. You will see a list of past and current experiments for this menu.
3. Click **New Experiment**.

### Step 3 — Configure the Experiment

Fill in the experiment form:

| Field | Description |
|---|---|
| Control version | The "safe" version — usually the current live menu |
| Variant version | The new version you want to test |
| Variant traffic | The percentage of customers who will see the variant (1–99%). 50% is a balanced split. |
| Start time | When the experiment begins — must be in the future |
| End time | When the experiment ends automatically |

Click **Create Experiment**. The experiment is saved in **Draft** status until its start time arrives.

### Step 4 — Monitor the Experiment

Click **Results** on any active or ended experiment to see:

- How many unique dining sessions were exposed to the control version
- How many unique dining sessions were exposed to the variant version
- How many orders were placed by sessions in each group

Review these numbers manually to judge whether the variant is performing better. Statistical significance is not calculated automatically in v1.

### Step 5 — Act on the Results

After the experiment ends, if the variant performed better:

1. Go to the **Versions** tab on the menu edit page.
2. Find the variant version.
3. Click **Activate** to make it the new live version for all customers.

If the control performed better (or results were inconclusive), no action is needed — the live menu continues unchanged.

## Managing Experiments

### Pausing an Experiment

If something goes wrong mid-experiment, you can pause it:

1. Open the experiment.
2. Click **Pause**.
3. New customers see the default active menu version. Customers already assigned to the experiment keep their assigned version until you end it.

### Ending an Experiment Early

1. Open the experiment.
2. Click **End Experiment**.
3. All customers immediately revert to the default active menu version.

Ending is permanent — you cannot restart an ended experiment.

## Experiment Lifecycle

| Status | What it means | Available actions |
|---|---|---|
| Draft | Created but not yet running | Edit, Delete |
| Active | Running — customers are being assigned | Pause, End |
| Paused | Temporarily stopped — no new assignments | End |
| Ended | Complete — results are frozen | View results only |

## How Customer Assignment Works

When a customer scans your QR code and starts a dining session:

1. The system checks whether an active experiment exists for the menu.
2. If one does, the customer's unique session token is used to calculate a bucket number between 0 and 99.
3. If the bucket falls below your variant traffic percentage, the customer sees the **variant**. Otherwise, they see the **control**.
4. Their assignment is stored for the session. Refreshing the page, adding items, or leaving and returning all show the same version.

Two customers at the same table will each be assigned independently based on their own session tokens.

## Key Concepts

**Control version** — the baseline menu. Usually your current live menu. If the experiment shows no clear winner, customers will continue seeing this version.

**Variant version** — the menu you are testing. It contains the changes you are evaluating.

**Traffic allocation** — the percentage of dining sessions routed to the variant. The remainder see the control. This cannot be changed once the experiment is active.

**Exposure** — a record created when a customer is served a menu as part of an active experiment. Each unique dining session generates one exposure record per experiment.

**Deterministic assignment** — a customer always sees the same version for their session, no matter how many times they reload or interact with the menu.

## Tips & Best Practices

- Test one change at a time. Changing both pricing and descriptions in the same variant makes it impossible to know which change caused the result.
- Run experiments for at least 3–5 days to collect enough sessions across different days of the week.
- A 50/50 split is the most common starting point. Use a lower variant percentage (e.g., 10–20%) if you want to test a risky change more cautiously.
- Check in on the exposure counts after the first day. If one version is receiving very few exposures, the split may not be working as expected — contact support.
- Name your versions clearly before creating an experiment. "Control — original prices March 2026" is much easier to interpret in results than "Version 3".

## Limitations & Known Constraints

- Only two-variant experiments are supported (control vs. one variant). Multi-variant testing is a future feature.
- Statistical significance is not calculated. You review raw exposure and order counts and make your own judgement.
- The allocation percentage cannot be changed once an experiment is active.
- Experiments for the same menu cannot overlap in time. You must end the current experiment before starting a new one for the same menu.
- Localised content (translated menu text) is not included in version snapshots — live translations are used at render time regardless of which version is assigned.
- Automatic winner promotion (the system picks the better version for you) is not available.

## Frequently Asked Questions

**Q: What happens to my menu when an experiment ends?**
A: All customers revert to the default active menu version automatically. No manual action is required. The experiment system also runs a job every 15 minutes to mark overdue experiments as ended, ensuring no experiment runs past its scheduled end time.

**Q: Can a customer change which version they see?**
A: No. Assignment is locked to their dining session. The same session always sees the same version. A new session (new QR scan) may be assigned to a different version.

**Q: If I edit a menu version while the experiment is running, does it affect the experiment?**
A: The experiment uses a snapshot of the version at the time the version was created. Changes to the live menu after the version was saved do not affect the experiment.

**Q: How do I promote the winning variant?**
A: After the experiment ends, go to the Versions tab, find the variant, and click Activate to make it the live menu.

**Q: The A/B Experiments link is not showing in my sidebar. What do I do?**
A: The `menu_experiments` Flipper flag must be enabled for your restaurant. Contact mellow.menu support to enable it.
