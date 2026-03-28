---
name: OrdrsController broadcast_state outside format block
description: broadcast_state called directly inside respond_to (not inside a format.* block) in update action — fires for all formats, HTML requests get 406
type: project
---

`app/controllers/ordrs_controller.rb` lines 466–471: `broadcast_state(@ordr, @tablesetting, @ordrparticipant)` is placed inside the `respond_to` block but outside any `format.*` sub-block. Rails `respond_to` only executes the matching format block; code outside a `format.*` block runs unconditionally for all formats. For HTML requests there is no `format.html` block here, causing `ActionController::UnknownFormat` or a 406. The broadcast also fires before the format handler returns.

**Why:** broadcast_state was inserted at the wrong indentation level relative to the format blocks.

**How to apply:** In respond_to blocks, any side-effect calls (broadcasts, event emissions) must be inside a specific format block or placed before the respond_to call entirely.
