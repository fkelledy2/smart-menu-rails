---
name: order_totals_controller.js grossNotPositive operator precedence bug
description: !x > 0 parsed as (!x) > 0 in JS — grossNotPositive always evaluates incorrectly, state-refresh fetch never fires on zero gross
type: project
---

`order_totals_controller.js` line 34:
```js
const grossNotPositive = !(typeof gross === 'number' ? gross : parseFloat(gross || 0)) > 0;
```

JS operator precedence: `!` binds tighter than `>`. This parses as `(!numericValue) > 0`. `!numericValue` is a boolean. `false > 0` is `false`, `true > 0` is `true`. So `grossNotPositive` is `true` only when the raw numeric is `0` or `NaN`, and `false` otherwise — but the check cannot be relied on as a meaningful boolean condition.

Intent: check whether gross is missing or zero to trigger a state-refresh fetch.

Fix: add parentheses: `!((typeof gross === 'number' ? gross : parseFloat(gross || 0)) > 0)`

**Why:** Classic JS operator precedence trap. Easy to write, hard to spot.

**How to apply:** When reviewing boolean guards on numeric values in JS, watch for `!x > y` patterns — always needs parens: `!(x > y)`.
