# Naked Domain Enablement & Canonical Domain Strategy

## Status
- Priority Rank: IQ-1 (Infrastructure Quick Win — ship before any public launch activity)
- Category: Infrastructure / Launch Readiness
- Effort: S
- Dependencies: DNS provider access, Heroku CLI access

---

## Problem Statement

mellow.menu currently serves traffic exclusively via `www.mellow.menu`. The apex (naked) domain `mellow.menu` is not registered as a Heroku custom domain and is not resolvable — any user who types or follows a link to `https://mellow.menu` receives an error. This is a trust and professionalism gap for a B2B SaaS platform: customers, investors, and press expect `mellow.menu` to work.

Additionally, having two canonical origins (`www` and naked) creates a duplicate-content SEO risk if both are allowed to serve without a redirect. QR codes already in the field use `https://www.mellow.menu/...` and must continue to work without modification.

---

## Success Criteria

- `https://mellow.menu` resolves correctly and serves the Rails application
- `https://www.mellow.menu` resolves correctly and serves the Rails application
- Both domains are registered in Heroku with valid SSL certificates
- A 301 permanent redirect fires for any `www.mellow.menu` request and forwards to `https://mellow.menu` with the full path and query string preserved
- No redirect loop exists between the two domains
- All existing QR codes (encoded as `https://www.mellow.menu/...`) continue to function — the redirect is transparent to the end user
- `robots.txt` and `sitemap.xml` updated to reference the canonical naked domain
- Zero downtime during rollout

---

## User Stories

**As a prospective restaurant owner**, I want `mellow.menu` to load in my browser so that the platform appears professional and trustworthy when I visit the URL from a pitch deck or business card.

**As a dining customer**, I want my QR code scan to work as before so that I am not affected by any infrastructure change.

**As the SEO owner**, I want all ranking signals to consolidate on `mellow.menu` so that the platform does not dilute its search authority across two origins.

**As a developer deploying a hotfix**, I want to know which domain is canonical so that any hardcoded URLs, email templates, and OG meta tags point to the right place.

---

## Functional Requirements

### 1. DNS Configuration

**DNS Provider: name.com** — name.com supports `ANAME` records at the apex. Use Option A.

**Option A — ANAME (confirmed viable for name.com)**

In the name.com DNS management panel, add:

```
mellow.menu       ANAME  →  mellow-menu.herokuapp.com
www.mellow.menu   CNAME  →  mellow-menu.herokuapp.com  (already exists — verify)
```

**Option B — Cloudflare DNS with proxy enabled (not needed, kept for reference)**

Cloudflare's DNS flattening is the fallback if ANAME is ever unavailable. Not required for name.com.

Do NOT use bare `A` records pointing to a Heroku IP address. Heroku's IP addresses are not stable and using A records will cause outages.

### 2. Heroku Domain & Certificate Registration

**`www.mellow.menu` is already registered on Heroku.** Only `mellow.menu` needs to be added:

```
heroku domains:add mellow.menu --app mellow-menu
heroku certs:auto:enable --app mellow-menu
```

Heroku will provision ACM (Automated Certificate Management) certificates for both domains. SSL certificates become active once DNS propagates and the domain ownership challenge is validated by ACM. This can take up to 60 minutes.

### 3. Rails: Allowed Hosts

Add both domains to `config/environments/production.rb` to prevent Rails from rejecting requests as DNS rebinding attacks:

```ruby
config.hosts << 'mellow.menu'
config.hosts << 'www.mellow.menu'
```

### 4. www → Naked 301 Redirect Middleware

Create `config/initializers/domain_redirect.rb`:

```ruby
class DomainRedirect
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.host == 'www.mellow.menu'
      return [301, { 'Location' => "https://mellow.menu#{req.fullpath}" }, []]
    end
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(0, DomainRedirect)
```

The middleware fires before all other Rack layers (including session, ActionDispatch, and asset pipeline). Inserting at position 0 ensures the redirect exits before any database or session work is done, keeping it fast and stateless.

Path and query string are preserved via `req.fullpath`. This ensures `https://www.mellow.menu/smartmenus/my-restaurant?table=3` redirects correctly to `https://mellow.menu/smartmenus/my-restaurant?table=3`.

### 5. robots.txt and sitemap.xml

Update `public/robots.txt` to reference the canonical domain:

```
User-agent: *
Allow: /
Sitemap: https://mellow.menu/sitemap.xml
```

The `sitemap.xml` canonical base URL must be updated from `https://www.mellow.menu` to `https://mellow.menu`. **The sitemap generation method is currently unknown** — the implementer must first run `grep -r "sitemap" public/ app/ config/` to determine whether it is a static file at `public/sitemap.xml`, a dynamic controller route, or a gem (e.g. `sitemap_generator`). Update the appropriate source. During the DNS propagation window both origins will serve the sitemap, which is acceptable as a temporary transition state.

### 6. Hardcoded URL Audit

Before deploying, audit the codebase for hardcoded `www.mellow.menu` references in contexts where the canonical URL matters (email templates, OG meta tags, `default_url_options`, mailer host config):

- `config/environments/production.rb` — `config.action_mailer.default_url_options`
- `app/views/layouts/` — OG and canonical `<link>` tags
- Any mailer view that renders an absolute URL
- `ActionMailer::Base.default_url_options[:host]` — set to `'mellow.menu'`

---

## Non-Goals (Out of Scope for v1)

- Per-restaurant custom domains (e.g., `menu.myrestaurant.com`) — a separate feature; do not design this implementation to block it.
- Cloudflare Workers edge redirect to reduce redirect latency — future enhancement; the ~50–150ms Rack redirect is negligible at current traffic.
- Automated QR generation migration from `www` to naked domain — existing QR codes work via redirect; new QR generation can be updated as a separate, low-urgency change.
- QR scan telemetry tracking `www` vs naked origin — future enhancement; capture in the analytics backlog.
- Removing `www.mellow.menu` from DNS or Heroku — this must never happen; existing QR codes in the field are permanent.

---

## Technical Design

### Architecture Notes

This feature is a thin infrastructure and Rack middleware change. It requires no new models, no Sidekiq jobs, no Pundit policies, and no Stimulus controllers. The implementation is:

1. DNS record changes (ops task — no code)
2. Heroku CLI commands (ops task — no code)
3. Three lines added to `config/environments/production.rb`
4. One new initializer: `config/initializers/domain_redirect.rb`
5. One line updated in `public/robots.txt`
6. One `default_url_options` host value updated in production config

Total code change is under 30 lines. Deployment risk is low.

### New Dependencies

No new dependencies required. `Rack::Request` is part of the Rails stack already.

### Data Model Changes

None.

### Service Objects

None.

### Background Jobs

None.

### Controllers & Routes

No new controllers or routes. The redirect fires at the Rack middleware layer before routing, so `config/routes.rb` is untouched.

### Frontend

No frontend changes. The redirect is transparent to Turbo and Stimulus.

### API / Webhooks

N/A. The redirect middleware responds only to `www.mellow.menu` hosts and passes all other requests through unchanged. API calls authenticated via JWT that include `www.mellow.menu` in the `Host` header will be 301'd — JWT API clients should be pointed at `mellow.menu` in their configuration.

---

## Security & Authorization

- [ ] No Pundit policy changes required
- [ ] No tenant scoping implications
- [ ] The redirect response includes no `Set-Cookie` header and writes no session data — stateless and safe
- [ ] Brakeman scan clean (no new user-controlled input surfaces introduced)
- [ ] No RackAttack rule changes required (throttle keys are IP-based and unaffected by domain name)
- [ ] Confirm no CSRF origin mismatch: Rails CSRF checks `Origin` header against `config.hosts`. Both domains added to `config.hosts` prevents `ActionController::InvalidAuthenticityToken` for requests arriving via either domain before the redirect fires.

---

## Redirect Loop Risk — Mitigation

A redirect loop would occur if `mellow.menu` requests were also redirected. The middleware checks `req.host == 'www.mellow.menu'` exactly. Requests to `mellow.menu` fall through to `@app.call(env)` unconditionally. There is no configuration path that produces a loop.

Before deploying, verify manually:

```
curl -I https://mellow.menu/
# Expect: HTTP/2 200 (no Location header)

curl -I https://www.mellow.menu/
# Expect: HTTP/1.1 301, Location: https://mellow.menu/

curl -I https://www.mellow.menu/smartmenus/my-slug?table=5
# Expect: HTTP/1.1 301, Location: https://mellow.menu/smartmenus/my-slug?table=5
```

---

## Testing Plan

- [ ] Request spec: `test/requests/domain_redirect_test.rb`
  - `GET https://www.mellow.menu/` → 301 to `https://mellow.menu/`
  - `GET https://www.mellow.menu/smartmenus/slug?table=3` → 301 to `https://mellow.menu/smartmenus/slug?table=3`
  - `GET https://mellow.menu/` → 200 (no redirect)
  - `GET https://mellow.menu/smartmenus/slug` → 200 (no redirect)
  - Query string preservation verified
  - Path preservation verified (including nested paths like `/restaurants/1/menus/2`)
- [ ] No redirect loop on repeated `curl -L` follow
- [ ] Existing system tests unaffected (they use `www.example.com` or no host)
- [ ] Run: `bin/fast_test` — all passing

---

## Implementation Checklist

### Ops — Before Code Deploy

- [ ] Log in to name.com DNS management for `mellow.menu`
- [ ] Add ANAME record: `mellow.menu` → `mellow-menu.herokuapp.com`
- [ ] Verify existing CNAME record: `www.mellow.menu` → `mellow-menu.herokuapp.com` (should already exist)
- [ ] Run `heroku domains:add mellow.menu --app mellow-menu`
- [ ] Run `heroku certs:auto:enable --app mellow-menu` (if not already enabled)
- [ ] Wait for ACM certificate issuance (up to 60 minutes)
- [ ] Verify both domains resolve with valid SSL: `curl -I https://mellow.menu` and `curl -I https://www.mellow.menu`

### Code Changes

- [ ] `config/environments/production.rb` — add `config.hosts << 'mellow.menu'` and `config.hosts << 'www.mellow.menu'`
- [ ] `config/initializers/domain_redirect.rb` — create `DomainRedirect` middleware
- [ ] `config/environments/production.rb` — update `config.action_mailer.default_url_options[:host]` to `'mellow.menu'`
- [ ] `public/robots.txt` — update Sitemap URL to `https://mellow.menu/sitemap.xml`
- [ ] Determine sitemap generation method (`grep -r "sitemap" public/ app/ config/`) and update base URL
- [ ] Audit email templates and OG meta tags for hardcoded `www.mellow.menu` references
- [ ] Write `test/requests/domain_redirect_test.rb`

### Quality

- [ ] All tests written and passing (`bin/fast_test`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Brakeman clean (`bundle exec brakeman`)

### Validation After Deploy

- [ ] `https://mellow.menu` loads the homepage — HTTP 200
- [ ] `https://www.mellow.menu` redirects to `https://mellow.menu` — HTTP 301 with path preserved
- [ ] Existing QR code scan completes successfully end-to-end (scan → www URL → 301 → naked domain → menu loads)
- [ ] No redirect loop (follow redirects via `curl -L` — terminates)
- [ ] SSL valid on both domains (green padlock in browser)
- [ ] `robots.txt` at `https://mellow.menu/robots.txt` lists canonical Sitemap URL
- [ ] Mailer-generated links in a test email use `mellow.menu` not `www.mellow.menu`

---

## Open Questions

1. ~~**DNS provider**~~ — **Resolved**: name.com. Use Option A (ANAME record at apex).
2. **Sitemap generation**: Unknown — implementer must run `grep -r "sitemap" public/ app/ config/` to locate the source before updating the canonical base URL.
3. ~~**`www.mellow.menu` Heroku registration**~~ — **Resolved**: already registered. Only `mellow.menu` needs to be added.
4. ~~**JWT API clients**~~ — **Resolved**: no active API consumers are using `www.mellow.menu`. No partner reconfiguration required.

---

## References

- Heroku Custom Domains documentation: https://devcenter.heroku.com/articles/custom-domains
- Heroku ACM (Automated Certificate Management): https://devcenter.heroku.com/articles/automated-certificate-management
- Cloudflare CNAME flattening at apex: https://developers.cloudflare.com/dns/cname-flattening/
- RFC 7231 §6.4.2 — 301 Moved Permanently
- Related spec: `docs/features/todo/backlog/square-integration.md` (no dependency — informational cross-reference for `Payments::Orchestrator` pattern)
