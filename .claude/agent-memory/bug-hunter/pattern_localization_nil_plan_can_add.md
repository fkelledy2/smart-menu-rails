---
name: Localization partial blocks language add when plan is nil
description: can_add_language is false when restaurant.user has no plan, permanently disabling Add Language for nil-plan restaurants
type: project
---

In `app/views/restaurants/sections/_localization_2025.html.erb` lines 14–21:
```erb
plan = restaurant.user&.plan
languages_limit = plan&.languages   # nil when no plan
can_add_language = languages_limit == -1 || (languages_limit.to_i > 0 && active_languages_count < languages_limit.to_i)
```

When `plan` is nil, `languages_limit` is nil. `nil == -1` is false. `nil.to_i` is 0, so `0 > 0` is false. Both conditions are false — `can_add_language` is `false`.

For restaurants where the owner has no plan row (e.g. during onboarding, or for admin-created restaurants), the Add Language button is permanently replaced with a disabled "language limit reached" button even though no limit has been configured.

**Fix**: treat a nil plan as unlimited (or at minimum as a non-blocking state):
```ruby
can_add_language = languages_limit.nil? || languages_limit == -1 || (languages_limit.to_i > 0 && active_languages_count < languages_limit.to_i)
```

**File**: `app/views/restaurants/sections/_localization_2025.html.erb` line 21
