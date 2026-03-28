---
name: OrdritemsController#update_ordr omits covercharge from gross
description: When items are added/removed, update_ordr recomputes gross as nett+tip+service+tax — missing covercharge. OrdrsController#calculate_order_totals correctly includes covercharge. Totals diverge for restaurants that use per-cover charges.
type: project
---

`OrdritemsController#update_ordr` (line ~450) computes:
```ruby
ordr.gross = ordr.nett.to_f + ordr.tip.to_f + ordr.service.to_f + ordr.tax.to_f
```

`OrdrsController#calculate_order_totals` computes:
```ruby
ordr.gross = ordr.nett + ordr.covercharge + ordr.tip + ordr.service + ordr.tax
```

Any restaurant using `menu.covercharge` (per-cover fee) will have incorrect `gross` after every item add/remove, because the covercharge component is stripped out. The `ordr.covercharge` column retains its value from the last `calculate_order_totals` call, but it is not added back in `update_ordr`.

**Why:** `update_ordr` is an older method that predates the covercharge feature; it was never updated.

**How to apply:** Add `ordr.covercharge.to_f` to the gross sum in `update_ordr`, matching `calculate_order_totals`. Also note taxes in `update_ordr` are applied only to `nett`, while `calculate_order_totals` applies them to `nett + covercharge` — both divergences need fixing together.
