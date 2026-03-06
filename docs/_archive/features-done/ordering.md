# Ordering Dashboard Plan

## Goals
- Provide a clear performance overview across menus, employees, and tables.
- Support quick time-window analysis, comparisons vs prior periods, and drill-downs.

## KPIs (top summary cards)
- Gross Revenue
- Net Revenue
- Taxes
- Tips
- Service Charges
- Orders Count
- Items Sold
- AOV (Average Order Value)
- Conversion Rate (optional)

Each card shows current value, delta vs previous period, and optional trend sparkline.

## Time ranges and filters
- Presets: Today, Yesterday, Last 7 Days, Last 28 Days, MTD, Last Month, Custom.
- Filters: Menu, Employee, Table, Order Status.
- Comparison: toggle vs previous period or same period last week.

## Visualizations (Chart.js)
- Revenue Over Time (Gross, Net)
- Orders Over Time
- Menu Mix (revenue or orders by menu)
- Top Items (qty or revenue)
- Staff Performance (revenue/orders by employee)
- Table Utilization (orders/revenue by table)

## Breakdown tables
- Orders table: id, created_at, menu, employee, table, status, totals.
- Items table: item, qty, revenue, menu. CSV export for current filters.

## Page layout (wireframe)
- Header: Restaurant name + date range + compare toggle.
- Row 1: KPI cards grid.
- Row 2: Revenue Over Time + Orders Over Time.
- Row 3: Menu Mix + Top Items.
- Row 4: Staff Performance + Table Utilization.
- Row 5: Orders table and Items table.

## Backend aggregations
- Inputs: restaurant_id, date range, filters.
- Aggregates: orders count, gross, net, taxes, tips, service; grouped by time, menu, employee, table.
- Items aggregates: qty and revenue by item and menu.
- Comparisons: run same query for prior period.
- Deliver JSON for charts/KPIs; HTML for tables.

## Data model and indices
- orders: indices on restaurant_id, created_at, status, menu_id, employee_id, table_id.
- order_items: indices on order_id, item_id, menu_id.
- Consider materialized views / summary tables for scale.

## Performance
- Cache per-restaurant + filter + time range.
- Precompute daily rollups; overlay live for Today.
- Paginate and lazy-load tables.

## Security
- Manager-only access. Validate restaurant ownership on endpoints.

## Implementation steps
1) Create dashboard partial with filters, KPI placeholders, and chart containers.
2) Add minimal JS initializer; later wire to Chart.js and JSON endpoints.
3) Implement endpoints for KPIs, timeseries, and breakdowns with caching.
4) Build tables and CSV export.
5) QA, responsive polish, and print-to-PDF.
