---
name: data-confirm vs data-turbo_confirm legacy pattern
description: data-{confirm:} fully migrated to data-{turbo_confirm:} across all operator views as of 2026-04-04
type: project
---

In Rails 7 + Turbo, `data: { confirm: 'message' }` does NOT trigger any confirmation dialog — it is a Rails UJS attribute that Turbo ignores. The correct Turbo pattern is `data: { turbo_confirm: 'message' }`.

**Status as of 2026-04-04:** FULLY MIGRATED. All operator-facing views have been swept. The following were fixed in this pass:
- metrics/_form, userplans/_form, menus/_form, menusections/_form, menuavailabilities/_form, hero_images/_form
- smartmenus/_form, ordractions/_form, ordritemnotes/_form, ordrparticipants/_form, ordrs/_form, ordritems/_form
- tags/_form, ingredients/_form, inventories/_form, restaurantavailabilities/_form, genimages/_form
- taxes/_form, employees/_form, tablesettings/_form, restaurants/_form (delete action)
- tracks/_form, menus/experiments/_list (end + delete), ordrnotes/_note_card
- sizes/edit, tips/edit, allergyns/edit (link_to in page headers converted to button_to)
- wait_times/_queue_list (data: { confirm: } duplicate removed, form-level turbo-confirm kept)
- menus/index_2025_example (data hash)

Also note: link_to with method: :delete is equally broken in Rails 7 + Turbo. All were converted to button_to.

**Why:** Turbo dropped support for data-confirm; buttons with this attribute silently delete/destroy without any confirmation.
**How to apply:** Pattern is fully cleared — if new scaffold-generated forms appear, check for both `data: { confirm:` and `link_to ... method: :delete`.
