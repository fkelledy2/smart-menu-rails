---
name: Test-only enableStaffButtons script defeats disabled assertions
description: show.html.erb has a Rails.env.test? script that removes 'disabled' from all add-item-btn-* buttons — tests cannot assert btn.disabled? for no-table cases
type: feedback
---

`app/views/smartmenus/show.html.erb` contains a test-only `<script>` block (inside `<% if Rails.env.test? %>`) that defines `enableStaffButtons()`. This function removes the `disabled` attribute from ALL `[data-testid^="add-item-btn-"]` buttons and retries 10 times every 50ms to defeat any late script that re-sets it.

**Why:** Added for automation stability so system tests can click add buttons without fighting the `ordr_commons.js` `menuItemsEnabled=false` disable logic.

**How to apply:**
- Never use `btn.disabled?` or `assert_selector 'button[disabled]'` for add-item buttons in system tests — the script will have removed the attribute.
- To test the "no table" / disabled state, assert `pointer-events: none` instead: `page.evaluate_script("document.querySelector('[data-testid=...]')?.style?.pointerEvents") == 'none'`. The `ordr_commons.js` CSS property is NOT cleared by `enableStaffButtons`.
- The script only targets `[data-testid^="add-item-btn-"]` so other button types are unaffected.
