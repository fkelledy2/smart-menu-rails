---
name: SizesController bulk_update runs authorize AFTER update_all — post-hoc auth is useless
description: SizesController#bulk_update calls update_all before iterating with authorize — mutation happens before the authorization check, making Pundit protection ineffective
type: project
---

In app/controllers/sizes_controller.rb lines 144-150:
```ruby
to_update.update_all(status: Size.statuses[status], updated_at: Time.current)

Size.where(id: ids).find_each do |size|
  authorize size, :update?
end
```

The update_all fires first, then authorize is called. If Pundit raises NotAuthorizedError on any size, the mutation has already occurred. This makes the authorization check useless as a guard — it only raises an exception after the fact.

Fix: authorize each record before mutating, using find_each first.

**Why:** Order of operations — update_all must come after authorization, not before.
**How to apply:** Always call authorize before the mutation it is meant to guard.
