---
name: pattern_menuitem_has_size_mappings_wrong_name
description: Menuitem#has_size_mappings? called menuitemsizemappings (wrong name) instead of menuitem_size_mappings — NoMethodError
type: feedback
---

`Menuitem#has_size_mappings?` called `menuitemsizemappings.any?` but the correct association name is `menuitem_size_mappings`.

**Why:** Likely a typo — the association is declared as `has_many :menuitem_size_mappings`. Rails does not camelise association names.

**Fix:** Changed to `menuitem_size_mappings.any?`.

**How to apply:** When scanning Menuitem, pay attention to association method calls at the bottom of the file — methods defined near the closing `end` are easy to miss in reviews.
