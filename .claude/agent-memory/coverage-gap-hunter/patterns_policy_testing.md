---
name: policy_testing_patterns
description: Pundit policy test patterns specific to the Smart Menu codebase (ApplicationPolicy nil coercion, owner? chain)
type: feedback
---

## Critical: ApplicationPolicy converts nil user to User.new

`ApplicationPolicy#initialize` does `@user = user || User.new`.
`User.new.present?` is TRUE in Ruby (object is not nil/false).

**Why:** This means any policy method checking `user.present?` will ALWAYS return true, even when the caller passes `nil`. Tests that assert denial for nil user on `user.present?` methods will FAIL.

**How to apply:**
- Only test denial for nil user when the policy method checks actual record ownership (e.g., `restaurant.user_id == user.id`, `user.persisted?`).
- For methods checking `user.present?`, write the test asserting TRUE, with a comment explaining the nil→User.new coercion.
- Test template: `policy = SomePolicy.new(nil, record); assert policy.index?  # nil becomes User.new, present? is true`

## Anonymous customer pattern

Several policies allow operations for "anonymous customers" using `user.persisted?`:
```ruby
return true unless user.persisted?  # Allow anonymous customers
```
`User.new.persisted?` returns FALSE — so an unpersisted user is treated as anonymous and granted access.
To simulate an anonymous customer: `@anon_user = User.new`
This applies to: `OrdritemPolicy`, `OrdrparticipantPolicy`, `MenuparticipantPolicy`

## owner? chain patterns

- Restaurant owner: `record.restaurant.user_id == user.id` OR `user.restaurants.exists?(id: record.restaurant_id)`
- Menu owner: `record.menu.restaurant.user_id == user.id`
- OCR owner: `record.ocr_menu_section.ocr_menu_import.restaurant.user_id == user.id`
- Ordritem owner: `record.ordr.restaurant.user_id == user.id`

## super_admin? check pattern

`super_admin?` checks `user.respond_to?(:super_admin?) && user.super_admin?`
Fixture: `users(:super_admin)` — has `super_admin: true`

## Scope pattern for nil user

Scopes that call `user.restaurants.pluck(:id)` will work on `User.new` (returns empty array).
The `scope.none` return for nil users is typically handled in the Scope#resolve method.

## Empty fixture files — create dynamically

`ordractions.yml` and `ordritemnotes.yml` are intentionally empty (avoid system test conflicts).
Create records in `setup` blocks:
```ruby
@ordr_action = OrdrAction.create!(
  ordr: ordrs(:one),
  actiontype: 'opened',
  ...
)
```
