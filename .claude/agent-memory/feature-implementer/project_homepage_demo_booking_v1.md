---
name: Homepage Demo Booking & Video v1
description: Demo booking lead capture, video analytics, admin CRM view — architecture and gotchas (March 2026)
type: project
---

Feature #7 — Homepage Demo Booking & Video — shipped 2026-03-26.

**Why:** Minimum viable sales funnel. Converts marketing traffic into bookable demo leads without CRM dependency.

**Models:**
- `DemoBooking` — lead capture with `RESTAURANT_TYPES`, `CONVERSION_STATUSES`, `LOCATION_COUNTS` constants. Email normalised (downcase/strip) via `before_validation`. `calendly_booking_url` method builds pre-fill URL from `CALENDLY_EVENT_URL` env var with graceful fallback.
- `VideoAnalytic` — insert-only engagement events. `VALID_EVENT_TYPES` includes play/pause/seeked/ended/completion_25/50/75/100.

**Controllers:**
- `DemoBookingsController` — fully public, skips auth/employee/permissions. Two actions: `create` (JSON) and `video_analytics` (JSON).
- `Admin::DemoBookingsController` — `require_mellow_admin!` guard (same pattern as Admin::MarketingQrCodesController). Supports CSV export via `respond_to format.csv`.

**Mailer:** `DemoBookingMailer#confirmation` — sends to prospect, CCs `demos@mellow.menu`. Attaches `demo_booking.ics` with `content_type: 'text/calendar; method=REQUEST'` generated via the `icalendar` gem (v2.x). ICS uses METHOD:REQUEST so email clients render Accept/Decline buttons. Attendees include prospect email and demos address with RSVP=TRUE. Placeholder dtstart = 2 business days from booking date at 10:00 UTC. HTML body includes a Google Calendar fallback link via `@google_cal_url`. Subject pattern: `"Your mellow.menu demo — {contact_name}"`. Uses private helpers `placeholder_start_time`, `ics_content`, `demo_description`, `google_calendar_url`.

**icalendar gem:** Use `Icalendar::Values::DateTime.new(time.strftime('%Y%m%dT%H%M%SZ'))` for UTC timestamps. Use `Icalendar::Values::CalAddress.new("mailto:addr", opts)` for ORGANIZER/ATTENDEE. Append METHOD to calendar with `cal.append_custom_property('METHOD', 'REQUEST')`. Use `event.append_attendee` (not `event.attendee=`) to add multiple attendees.

**Routes:** `resources :demo_bookings, only: [:create]` with `collection { post :video_analytics }`. Standalone `/demo` page via `get '/demo', to: 'home#demo'`. Admin: inside existing `namespace :admin` block.

**Rack::Attack:** `demo_bookings/ip` — 5/hour, `video_analytics/ip` — 60/minute.

**Asset manifest:** New Stimulus controllers must be added to `app/assets/config/manifest.js` individually (not auto-discovered). Forgetting this causes ActionView::Template::Error in tests.

**Stimulus:** `demo-booking` controller handles form submit, error display, and Calendly success transition. `video-analytics` controller fires milestone events (25/50/75/100%) with sentinel guards to prevent duplicate fires. Uses private class fields (`#sentinels`, `#post`, etc.).

**Video:** Rendered only when `DEMO_VIDEO_URL` env var is set. Falls back to a "coming soon" placeholder that links back to the live demo booking modal — no broken embed.

**Homepage:** Demo CTA button in hero section (`index.html.erb`) is a `link_to demo_path` — not a modal trigger. The `/demo` standalone page (`demo.html.erb`) still has the "Book live demo" button as a modal trigger (intentional — the modal lives on that page). Modal partials rendered at bottom of `<% else %>` block (anonymous user path only). Translation keys `bookDemo` and `watchDemo` added to `config/locales/en/home.en.yml`.

**Stimulus success flow:** After successful form submission the controller replaces the form step innerHTML with an inline confirmation message ("Thanks! We'll be in touch shortly."), then after 2 seconds calls `bootstrap.Modal.getInstance(modalEl).hide()` to close the modal. The Calendly success step is then shown for if/when the modal is reopened.

**How to apply:** When adding new public-facing controllers, skip all auth/employee before_actions explicitly with `raise: false`. When adding new Stimulus controllers, always add to both `controllers/index.js` AND `app/assets/config/manifest.js`.
