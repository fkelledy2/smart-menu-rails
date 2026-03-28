---
name: JWT download_link sends raw token in GET query string
description: The download_link admin action is a GET route; the view passes raw_jwt via a hidden form field, which becomes a URL query parameter — the raw JWT appears in server access logs
type: project
---

`Admin::JwtTokensController#download_link` is a GET route (`config/routes.rb` line 121). The view (`app/views/admin/jwt_tokens/show.html.erb` line 32-33) submits a form with `method: :get` and passes `raw_jwt` as a hidden field:

```erb
<%= form_with url: download_link_admin_jwt_token_path(@token), method: :get ... do |f| %>
  <%= f.hidden_field :raw_jwt, value: flash[:raw_jwt] %>
```

This results in: `GET /admin/jwt_tokens/:id/download_link?raw_jwt=eyJ...` — the full JWT is written into every web server access log, Heroku log drain, and any log aggregator.

**Why:** Should be POST (or at minimum use a one-time download token stored server-side).

**How to apply:** Change `download_link` route to POST, update the form's `method:` to `:post`, and update the route/controller accordingly. Or generate a short-lived signed download URL and redirect to it.
