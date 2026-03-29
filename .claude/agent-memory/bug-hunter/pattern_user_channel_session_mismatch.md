---
name: UserChannel stream name / broadcast name mismatch and no auth
description: UserChannel subscribed to client-supplied session_id stream; KitchenBroadcastService broadcasts to user_#{id}_channel — names never matched, no auth check
type: feedback
---

`UserChannel` (pre-fix) streamed from `user_#{params[:session_id]}_channel` with no authentication check. `KitchenBroadcastService#broadcast_staff_assignment` broadcasts to `user_#{staff_user.id}_channel`. The two formats never matched, so staff assignment notifications were silently dropped. Also, any authenticated or unauthenticated client could subscribe and snoop by guessing session IDs.

Fixed: `UserChannel#subscribed` now rejects unauthenticated connections and streams from `user_#{current_user.id}_channel`, matching the broadcast name.

**Why:** When two components independently define a channel name, they must use the same key — always `user.id` for per-user channels, never a client-supplied opaque token.

**How to apply:** Per-user ActionCable channels must derive stream names from server-controlled identity (`current_user.id`), never from client-supplied params.
