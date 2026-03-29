---
name: SpotifyPlaylistSyncJob nil dereference
description: @restaurant.name called before nil guard — NoMethodError when restaurant not found
type: project
---

`SpotifyPlaylistSyncJob#perform` called `@restaurant.name` and `@restaurant.spotifyuserid` on lines 10–11 before the `return unless @restaurant` guard on line 12. If `Restaurant.find_by(id: args[0])` returns nil (unknown id or empty args), both debug log calls crash with NoMethodError before the guard is ever reached.

**Why:** Classic guard-after-use ordering mistake; likely written quickly and debug lines added above the guard.

**How to apply:** Any job using find_by + nil guard — make sure the guard is the very first thing after the find_by call, before any attribute access.
