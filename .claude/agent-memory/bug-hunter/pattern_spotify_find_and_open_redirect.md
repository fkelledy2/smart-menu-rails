---
name: Restaurants::SpotifyController unrescued find + open redirect via session
description: spotify_callback used Restaurant.find (500 on missing ID) + passed unvalidated session[:spotify_return_to] as redirect
type: feedback
---

`Restaurants::SpotifyController#spotify_callback` (line 75) called `Restaurant.find(session[:spotify_restaurant_id])` without rescue — raises `RecordNotFound` (500) if the restaurant was deleted between the OAuth start and the callback.

Also, `return_path = session.delete(:spotify_return_to) || edit_restaurant_path(...)` then `redirect_to return_path` without validation — an attacker who can set `session[:spotify_return_to]` (e.g., via CSRF on the `spotify_auth` action which reads `params[:return_to]` into the session) could redirect the user to any URL after OAuth.

**Fix:** Changed `Restaurant.find` to `Restaurant.find_by` with nil guard and early redirect. Validated `stored_path` starts with `/` before using it; otherwise falls back to the safe edit path.

**Why:** The Spotify OAuth callback is a 3rd-party redirect — `session[:spotify_return_to]` was set earlier from `params[:return_to]` without validation in `spotify_auth`. The pair form an open redirect chain.

**How to apply:** Any stored redirect path in session must be validated to be a relative path (`start_with?('/')`) before use. `allow_other_host: true` in `redirect_to` should be treated as a red flag whenever user-controlled data is in the URL.
