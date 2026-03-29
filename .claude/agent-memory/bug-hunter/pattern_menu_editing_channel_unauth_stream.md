---
name: MenuEditingChannel unauthenticated stream subscription
description: MenuEditingChannel called stream_from before current_user guard — unauthenticated connections received all menu editing events
type: feedback
---

`MenuEditingChannel#subscribed` in `app/channels/menu_editing_channel.rb` called `stream_from "menu_#{menu_id}_editing"` on line 6, then checked `return unless current_user` on line 9. Once `stream_from` is called the connection is registered; the early return only stopped the presence/session tracking, not the stream subscription.

Fixed: moved `return reject unless current_user` before `stream_from`.

**Why:** In ActionCable, `stream_from` commits the subscription. Auth checks must come before it.

**How to apply:** In every ActionCable channel `subscribed` method, place all authorization/authentication `reject` guards before the first `stream_from` call.
