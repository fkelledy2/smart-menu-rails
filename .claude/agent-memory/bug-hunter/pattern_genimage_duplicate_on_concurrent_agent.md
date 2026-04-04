---
name: enqueue_image_generation creates duplicate genimages under concurrent agent runs
description: genimages has no UNIQUE constraint on menuitem_id — concurrent runs both see no genimage and both create one + both enqueue image generation
type: project
---

`MenuOptimizationWorkflow#enqueue_image_generation` (lines 538-557) checks:
```ruby
return if menuitem.genimage.present?
genimage = Genimage.create!(menuitem: menuitem, ...)
MenuItemImageGeneratorJob.perform_later(genimage.id)
```

`genimages.menuitem_id` has only a non-unique index. Two concurrent agent runs can both see `menuitem.genimage.nil?` and both create a genimage and enqueue a generator job. No unique constraint exists to prevent this.

**Fix:** Add a partial unique index on `genimages(menuitem_id)` where `menuitem_id IS NOT NULL`, and rescue `RecordNotUnique` in `enqueue_image_generation`.

**How to apply:** Any time the agent framework is suspected of generating duplicate images for the same item.
