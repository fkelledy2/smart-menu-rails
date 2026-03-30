# Branded Email Styling

## Status
- Priority Rank: #2
- Category: Launch Blocker
- Effort: S
- Dependencies: None

## Problem Statement
All system emails sent by mellow.menu during registration, onboarding, and transactional flows currently use unbranded default templates. This damages first impressions for restaurant owners signing up, undermines trust in the platform, and makes the product look unfinished at the point of first contact. Branded emails are a launch baseline, not a nice-to-have.

## Success Criteria
- A shared branded mailer layout (`app/views/layouts/mailer.html.erb`) is applied to all outgoing email types.
- Logo, brand colours, and consistent typography are present in all emails.
- All Devise emails (confirmation, password reset, unlock), welcome email, and order-related emails use the new layout.
- Emails are tested and render correctly in Gmail, Apple Mail, and Outlook (or equivalent preview tool).
- Mobile-responsive layout (single-column, min 16px font, touch-friendly CTAs).

## User Stories
- As a new restaurant owner, I want to receive a professional branded welcome email so I feel confident in the platform I just signed up for.
- As a developer, I want a single shared mailer layout so all new emails automatically inherit the brand.
- As marketing, I want consistent colour and typography across all email touchpoints.

## Functional Requirements
1. Create or update `app/views/layouts/mailer.html.erb` with branded header (logo), content yield, and footer (legal links, unsubscribe placeholder).
2. Create `app/views/layouts/mailer.text.erb` for plain-text equivalent.
3. All existing Devise mailer views must render within this layout without layout overrides.
4. Create a reusable `_email_styles` partial or inline the CSS (email clients require inline styles).
5. Brand colours applied: use the established Mellow Menu palette (confirm with design/brand assets in `app/assets/images/`).
6. Footer must include: copyright, website link, support link, and unsubscribe link (tokenised where required by GDPR).
7. Email subject lines must be reviewed and updated to use the Mellow Menu brand name consistently.
8. A `UserMailer#welcome_email` is created or confirmed to exist and triggered on user registration.
9. Emails must render correctly for the five most critical types: (a) email confirmation, (b) password reset, (c) welcome, (d) order receipt, (e) onboarding progress reminder.

## Non-Functional Requirements
- No new JavaScript dependencies.
- All CSS must be inline-compatible (email clients strip `<style>` blocks in many cases — use a CSS inliner or write inline styles directly).
- Images must use absolute URLs pointing to CDN-hosted or asset-pipelined assets.
- Max email width: 600px container for email client compatibility.
- Minimum font size: 16px body text.

## Technical Notes
- Modify `app/mailers/application_mailer.rb` to set `layout 'mailer'` and default from address `Mellow Menu <hello@mellow.menu>`.
- Devise mailer views live in `app/views/devise/mailer/` — update each view to use content_for blocks compatible with the shared layout, or override `DeviseMailer` to use the branded layout.
- Use `ActionMailer::Base.default` for from address configuration in `config/application.rb` or initializer.
- Use Rails asset helpers with `asset_url()` (not `asset_path()`) for email images to generate absolute URLs.
- No Pundit policy required (mailers are not request-scoped).
- No Flipper flag needed — this is a baseline change applied globally.
- No Sidekiq jobs needed unless email sends are moved to background delivery (use `deliver_later` where not already).

## Acceptance Criteria
1. Opening `http://localhost:3000/rails/mailers` (letter_opener or ActionMailer preview) shows the branded layout for all email types.
2. All Devise emails (confirmation, reset password) render the Mellow Menu logo in the header.
3. The footer in every email contains a link to the website and a support contact.
4. `UserMailer.welcome_email(user).deliver_later` enqueues without error and renders the branded layout.
5. Plain text version is present and readable for all email types.
6. No email contains raw HTML output that exposes template engine errors or default Rails styling.

## Out of Scope
- Email analytics / open-rate tracking (post-launch).
- A/B testing email subject lines (post-launch).
- Transactional SMS (covered by branded-receipt-email spec).
- Marketing automation sequences (post-launch).
- Custom per-restaurant email branding (post-launch — this is platform-level branding only).

## Open Questions
1. Are brand assets (logo PNG, colour palette) finalised and available in `app/assets/images/`? Must be confirmed before development starts.
2. Is there an existing `UserMailer` or should one be created? Check `app/mailers/` for existing mailer structure.
3. Should Devise confirmation emails require the branded layout from day one, or is there a legacy concern with existing confirmed users? (No concern — layout change is transparent to existing users.)
