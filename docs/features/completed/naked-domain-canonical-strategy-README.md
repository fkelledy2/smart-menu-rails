# Naked Domain Canonical Strategy — User Guide

**Shipped**: 2026-03-31
**Spec**: `docs/features/completed/naked-domain-canonical-strategy.md`

---

## What was built

`mellow.menu` (the naked/apex domain) is now the canonical URL for the platform. All traffic arriving via `www.mellow.menu` is automatically redirected to `mellow.menu` with a 301 permanent redirect. Existing QR codes encoded with `www.mellow.menu/...` continue to work — users are transparently forwarded to the correct URL.

---

## What changed in the codebase

### New file

**`config/initializers/domain_redirect.rb`**

A Rack middleware class (`DomainRedirect`) inserted at position 0 in the middleware stack. It checks `req.host == 'www.mellow.menu'` and, if true, returns a 301 to `https://mellow.menu` with the full path and query string preserved via `Rack::Request#fullpath`. All other hosts pass through untouched. The middleware is stateless — it writes no session data and sets no cookies.

### Updated files

| File | Change |
|------|--------|
| `config/sitemap.rb` | `SitemapGenerator::Sitemap.default_host` changed from `https://www.mellow.menu` to `https://mellow.menu` |
| `public/robots.txt` | Sitemap URL updated from `https://www.mellow.menu/sitemap.xml.gz` to `https://mellow.menu/sitemap.xml.gz` |
| `app/controllers/explore_controller.rb` | Canonical URLs updated to naked domain |
| `app/controllers/guides_controller.rb` | Canonical URLs updated to naked domain |
| `app/controllers/api/v2/base_controller.rb` | `X-Data-Attribution` header updated |
| `app/controllers/smartmenus_controller.rb` | OG URL and OG image fallback updated |
| `app/serializers/schema_org_serializer.rb` | `smartmenu_url` method updated |
| `app/views/shared/_head.html.erb` | OG/Twitter meta defaults and canonical `<link>` updated |
| `app/views/layouts/mailer.html.erb` | Footer links updated |
| `app/views/layouts/mailer.text.erb` | Footer links updated |
| `app/views/user_mailer/*.html.erb` / `*.text.erb` | Contact links updated |
| `app/views/contact_mailer/receipt.*` | Homepage links updated |
| `app/views/demo_booking_mailer/confirmation.text.erb` | Terms/privacy links updated |
| `app/mailers/demo_booking_mailer.rb` | Fallback host constant updated |
| `test/integration/seo_api_v2_test.rb` | Attribution header assertion updated |
| `test/integration/seo_structured_data_test.rb` | Schema URL assertion updated |
| `test/serializers/schema_org_serializer_test.rb` | Schema URL assertion updated |
| `test/controllers/api/v2/restaurants_controller_test.rb` | Attribution header assertion updated |

### New test file

**`test/requests/domain_redirect_test.rb`** — 9 tests covering:
- `www.mellow.menu/` → 301 to `mellow.menu/`
- Nested path preservation
- Query string preservation
- Path + query string preservation together
- No `Set-Cookie` header on redirect response
- Empty redirect body
- Naked domain requests are not redirected (200 pass-through)
- Smartmenu path on naked domain is not redirected
- No redirect loop

---

## Remaining ops steps (outside the codebase)

These steps must be completed by a person with DNS and Heroku access before the redirect works in production:

1. **Log in to name.com** DNS management for `mellow.menu`
2. **Add an ANAME record**: `mellow.menu` → `mellow-menu.herokuapp.com`
3. **Verify the existing CNAME record**: `www.mellow.menu` → `mellow-menu.herokuapp.com` (should already exist)
4. **Register the naked domain on Heroku**: `heroku domains:add mellow.menu --app mellow-menu`
5. **Enable ACM certificates**: `heroku certs:auto:enable --app mellow-menu` (if not already enabled)
6. **Wait up to 60 minutes** for DNS propagation and ACM certificate issuance
7. **Verify both domains** after propagation:
   ```
   curl -I https://mellow.menu/
   # Expect: HTTP/2 200

   curl -I https://www.mellow.menu/
   # Expect: HTTP/1.1 301, Location: https://mellow.menu/
   ```

---

## How the redirect works

```
User types mellow.menu         → Heroku routes to Rails → 200 (normal)
QR code scans www.mellow.menu  → DomainRedirect fires  → 301 to mellow.menu (transparent)
www.mellow.menu/t/abc?table=3  → 301 to mellow.menu/t/abc?table=3
```

The middleware is at Rack position 0, so it exits before session, CSRF, ActionDispatch, or any database work is done. This keeps redirects fast (~1ms) with zero database load.

---

## Canonical domain is now `mellow.menu`

All new hardcoded URLs, email templates, OG tags, and sitemap entries should use `https://mellow.menu` (no `www`). The `config.action_mailer.default_url_options[:host]` in `config/environments/production.rb` is already set to `'mellow.menu'`.

For local development, the middleware only activates when `Host == 'www.mellow.menu'`, so it has no effect on `localhost:3000`.

---

## User-Agent strings (not changed)

The `SmartMenuBot` user-agent strings in web scraper services (`menu_discovery/`, `menu_source_change_detector.rb`) still reference `https://www.mellow.menu` as the bot identifier URL. These are contact/attribution strings for third-party websites being scraped, not canonical URLs. They are intentionally left as `www.mellow.menu` because `www` will continue to resolve (via redirect) and changing them is low priority with no SEO impact.

---

## Terms page text (not changed)

The `app/views/home/terms.html.erb` file contains prose references to `www.mellow.menu` as a human-readable domain name in the legal text (e.g., "By accessing or using our website (www.mellow.menu)..."). These are legal document references and were not changed as part of this infrastructure task. They should be reviewed by whoever owns the terms copy.
