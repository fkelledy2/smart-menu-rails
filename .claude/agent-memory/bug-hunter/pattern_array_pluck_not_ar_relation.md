---
name: Array#pluck does not exist in Ruby 3.3 — use map
description: Array#pluck is not defined in Ruby 3.3 — Rails/Pluck rubocop cop incorrectly suggests it for plain Hash arrays
type: feedback
---

`Array#pluck` does not exist in Ruby 3.3. `ActiveRecord::Relation#pluck` is an AR-only method. When building a plain Ruby Hash from `each_with_object`, calling `.values.pluck(:key)` on the resulting Array raises `NoMethodError: undefined method 'pluck' for Array`.

Use `.map { |h| h[:key] }` instead.

The `Rails/Pluck` RuboCop cop will flag `map { |h| h[:key] }` and suggest `.pluck(:key)`. Add `# rubocop:disable Rails/Pluck` with a comment explaining the Array context — the directive must have a separate comment line before it (directive comment cannot have inline explanation text).

**Why:** This burned us in `MenuOptimizationWorkflow#build_tagged_items` — `order_counts.values.pluck(:order_count)` raised NoMethodError in every prod workflow run (P1). Tests didn't catch it because the test fixture had no orders so `order_counts` was empty and `compute_median([])` returned 0 safely.

**How to apply:** Any time you see `.values.pluck(...)` or `.map { |h| h[key] }` on a plain Ruby Hash/Array result (not an AR query), use `map` not `pluck`. Watch for this pattern especially in `each_with_object` hash builds followed by `.values`.
