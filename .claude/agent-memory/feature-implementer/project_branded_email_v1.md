---
name: Branded Email Styling v1
description: Implementation decisions, key findings, and gotchas from Branded Email Styling feature (March 2026)
type: project
---

Branded email styling shipped 2026-03-24. All mailer layouts, views, and tests updated.

**Why:** Unbranded default templates made the platform look unfinished at first contact. Launch blocker.

**Key decisions:**

1. Confirmable is NOT enabled on the User model — `confirmation_url` route does not exist. Removed `confirmation_instructions` override from `UserMailer` and its views to avoid routing errors.

2. The branded mailer layout (`app/views/layouts/mailer.html.erb`) uses a table-based email-safe structure with fully inline CSS. Brand primary: `#2563EB`. Background: `#F3F4F6`. Card: white with `#E5E7EB` border, 12px radius.

3. `UserMailer` inherits from `Devise::Mailer` (not `ApplicationMailer`) with `default template_path: 'user_mailer'` — it shadows the `app/views/devise/mailer/` views entirely.

4. The from address was updated from `admin@mellow.menu` to `Mellow Menu <hello@mellow.menu>` across all mailers including ContactMailer.

5. The ContactMailer notification `to:` address was updated from `admin@mellow.menu` to `hello@mellow.menu` to match the branded from address.

6. Integration tests that used `notification_email.body.encoded` for content assertions were failing after the migration to multipart emails — QP encoding wraps long strings. Fixed by using `.html_part.body.decoded` instead.

7. All user_mailer views now have matching `.text.erb` plain-text counterparts. Same for contact_mailer and staff_invitation_mailer.

8. `test/mailers/user_mailer_test.rb` must include `Rails.application.routes.url_helpers` to resolve URL helpers like `edit_password_url`. Also requires `default_url_options[:host]` in setup.

**Files created/modified:**
- `app/mailers/application_mailer.rb` — updated from address
- `app/mailers/user_mailer.rb` — removed confirmation_instructions, added email_changed/password_change overrides
- `app/mailers/contact_mailer.rb` — updated from/to addresses
- `app/views/layouts/mailer.html.erb` — full branded layout
- `app/views/layouts/mailer.text.erb` — branded plain-text layout
- `app/views/user_mailer/*.html.erb` — all 5 user mailer views rewritten
- `app/views/user_mailer/*.text.erb` — all 5 text variants created
- `app/views/contact_mailer/*.html.erb` — both views rewritten
- `app/views/contact_mailer/*.text.erb` — both text variants created
- `app/views/staff_invitation_mailer/invite.html.erb` — stripped redundant inline header/footer
- `test/mailers/user_mailer_test.rb` — full test suite (35 tests, 79 assertions)
- `test/mailers/contact_mailer_test.rb` — updated test suite
- `test/integration/contact_email_delivery_test.rb` — updated for new addresses and decoded body assertions
- `test/mailers/previews/*.rb` — all 3 previews populated

**How to apply:** When building future mailers, inherit from `ApplicationMailer`, use `deliver_later`, and let the shared layout handle header/footer. Never duplicate the layout chrome inside a view body.
