---
name: Menuitem methods outside class scope
description: size_cost_analysis and has_size_mappings? defined after class closes in menuitem.rb — NoMethodError on any call
type: project
---

`app/models/menuitem.rb` line 422 closes the `Menuitem` class. Lines 425–431 define `size_cost_analysis` and `has_size_mappings?` at top-level scope. Any call to these methods on a `Menuitem` instance raises `NoMethodError`.

**Why:** Methods were appended after the closing `end` without noticing the class had already closed.

**How to apply:** When investigating missing-method errors on `Menuitem`, check whether the method appears after line 422. Also a signal to check other large model files for the same pattern.
