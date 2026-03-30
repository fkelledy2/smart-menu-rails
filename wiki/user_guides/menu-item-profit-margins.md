# Menu Item Profit Margins — User Guide

## Overview

The Menu Item Profit Margin tools let you track the cost of each menu item, see your actual profit margins, and get AI-powered recommendations for pricing and menu changes. From manually entering ingredient costs to running a full menu engineering analysis, this feature gives restaurant owners the financial insight to make better decisions about what to serve and how to price it.

## Who This Is For

Restaurant owners and managers responsible for menu pricing and food cost management.

## Prerequisites

- You must have owner or manager access to the restaurant.
- No feature flag is required — profit margin tools are available to all restaurants.

## How To Use

### Step 1 — Enter Costs for a Menu Item

1. Go to your restaurant dashboard and open **Menu** > **Items**.
2. Click on any menu item.
3. Select the **Cost** tab.
4. Enter costs across four categories:
   - **Ingredient cost** — raw food cost
   - **Labour cost** — preparation time value
   - **Packaging cost** — containers, wrappers, etc.
   - **Overhead cost** — a portion of kitchen overheads
5. Click **Save costs**.

The system calculates the profit margin automatically based on the item's selling price.

### Step 2 — Set Up Ingredients (for Recipe-Based Costing)

For more accurate automatic costing, link ingredients to menu items:

1. Go to **Menu** > **Ingredients**.
2. Click **New Ingredient** or **Import from CSV** to add your ingredients with unit costs.
3. Return to a menu item, open the **Cost** tab, and select **Recipe-based costing**.
4. Add each ingredient with its quantity.
5. The item cost updates automatically whenever an ingredient cost changes.

To import ingredients in bulk, download the CSV template from the Ingredients page, fill it in, and upload it.

### Step 3 — View Your Profit Margin Dashboard

In the restaurant sidebar, click **Profitability** > **Overview** (or navigate directly to `/restaurants/[id]/profit_margins`).

The dashboard shows:

- A chart of profit margin trends over time
- Margin breakdown by menu category
- Your top 10 highest-margin items
- Your bottom 10 lowest-margin items
- Profit by day of week and hour of day
- Items flagged as high-margin but low-stock (inventory alerts)

You can export any report as a CSV file.

### Step 4 — Set Margin Targets

1. On the Profit Margins page, click **Targets**.
2. Set target margins at three levels:
   - Restaurant-wide default
   - Per menu category
   - Per individual menu item
3. Items below their target are highlighted in the dashboard.

### Step 5 — Run a Menu Engineering Analysis

Menu Engineering classifies every item into one of four strategic groups based on its popularity and profitability:

| Category | What it means |
|---|---|
| Stars | High profit, high popularity — your best performers |
| Plowhorses | Low profit, high popularity — popular but costly |
| Puzzles | High profit, low popularity — hidden gems to promote |
| Dogs | Low profit, low popularity — candidates for removal |

To run the analysis:

1. In the restaurant sidebar, click **Profitability** > **Menu Optimisations** (or navigate to `/restaurants/[id]/menu_optimizations`).
2. Click **Run Analysis**.
3. Review the matrix showing where each item falls.
4. Use the recommendations panel to see suggested actions for each category.

### Step 6 — Get AI Pricing Recommendations

1. On the Menu Optimisations page, click **AI Pricing Recommendations**.
2. The system analyses your cost data, sales volumes, and current prices, then suggests optimal price adjustments.
3. Review each recommendation. Each one shows the estimated revenue impact.
4. Accept or reject individual suggestions.

### Step 7 — Review Bundling Opportunities

1. On the Menu Optimisations page, click **Bundling Opportunities**.
2. The system identifies items that are frequently ordered together and suggests bundle pricing.
3. Review the suggested bundles and their projected impact on average order value.

### Step 8 — Apply Optimisations

You can apply approved recommendations in two ways:

**Semi-automatic mode** — review a list of prioritised actions and select which ones to apply. Click **Apply Selected** to make the changes.

**Automatic mode** (optional) — enable auto-apply to have approved price adjustments applied without manual review. A full audit trail records every change made automatically. This mode is off by default and should only be enabled after reviewing your data carefully.

## Key Concepts

**Profit margin** — the percentage of the selling price that is profit, after all costs. Calculated as: `(selling price - total cost) / selling price × 100`.

**Cost versioning** — every time you update a cost, the previous value is saved. You can review the full history of cost changes for any item.

**Menu Engineering Matrix** — the Stars/Plowhorses/Puzzles/Dogs framework for categorising menu items. Thresholds are calculated from your actual data (median popularity and median margin), not fixed numbers.

**AI cost estimation** — when you import a menu via OCR (photo or PDF), the system can use AI to suggest approximate ingredient costs for new items, saving time on initial data entry.

**Size mapping costs** — if a menu item is available in multiple sizes (e.g., small, medium, large), you can set different costs per size to get accurate per-size margins.

## Tips & Best Practices

- Start with your top-selling items. Getting accurate costs for your 10 most popular items will give you the most useful insight quickly.
- Update ingredient costs whenever your supplier prices change. The cascade update will automatically recalculate margins for all items using that ingredient.
- Pay close attention to Plowhorses — these are your most popular items but they are pulling down your average margin. Even a small price increase or cost reduction on a Plowhorse can have a large financial impact.
- Review the Menu Engineering Matrix monthly, not just when launching new items.
- Use the AI pricing recommendations as a starting point, not a final answer. Your local market knowledge matters.

## Limitations & Known Constraints

- Profit margin analysis requires cost data to be entered. Items with no cost data show no margin information.
- AI cost estimation is a rough guide — it should be verified against your actual supplier invoices.
- Automatic mode price adjustments require a human review of the audit trail to catch any unexpected changes.
- The bundling analysis is based on order history. New restaurants with limited order data may not see meaningful bundle suggestions until more orders have been placed.
- Margin targets are set in percentage terms. There is no fixed-dollar-amount target option in v1.

## Frequently Asked Questions

**Q: Do I need to enter costs for every single menu item?**
A: No — the dashboard will show data only for items that have costs entered. You can start with a subset and add more over time. Items without cost data simply do not appear in margin reports.

**Q: If I change an ingredient price, does it update all menu items that use it?**
A: Yes. Updating an ingredient's cost triggers automatic recalculation of the cost for every menu item that includes that ingredient in its recipe.

**Q: What is the difference between manual cost entry and recipe-based costing?**
A: Manual entry is simpler and faster — you just enter a total cost per item. Recipe-based costing links specific ingredients with quantities, so your costs stay accurate as ingredient prices change.

**Q: How does the AI pricing recommendation work?**
A: It analyses your item's current price, cost, sales volume, and how it fits into the menu engineering matrix. It then suggests a price that improves your margin without being likely to significantly reduce demand. It is a data-driven suggestion, not a guarantee.

**Q: Can I export profit margin data for my accountant?**
A: Yes. CSV export is available on the Profit Margins report page.
