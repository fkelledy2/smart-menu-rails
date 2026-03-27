# Homepage Demo Booking & Video

## Status
- Priority Rank: #7
- Category: Launch Enhancer
- Effort: S
- Dependencies: None (marketing site / homepage only)

## Problem Statement
mellow.menu has no structured way for prospective restaurant owners to book a demo or watch a recorded product walkthrough. Without these conversion mechanisms, marketing spend drives traffic to a homepage that cannot convert visitors into leads. A demo booking form and embedded video are the minimum viable sales funnel for a B2B SaaS product at this stage.

## Success Criteria
- Homepage has a prominent "Book a Demo" CTA that captures lead information (name, restaurant name, email, restaurant type, location count).
- Lead data is captured in a `demo_bookings` table and routed to the sales team.
- An automated confirmation email is sent to the prospect.
- A Calendly (or equivalent) scheduling widget appears after form submission.
- A recorded demo video is embedded on the homepage with basic engagement tracking.
- Mobile-responsive on all screen sizes.

## User Stories
- As a restaurant owner visiting the homepage, I want to book a live demo easily so I can learn whether mellow.menu fits my needs.
- As a restaurant owner, I want to watch a recorded demo at my own pace so I can evaluate the product before committing to a call.
- As the sales team, I want leads captured with context (restaurant type, size) so I can prioritise follow-up.

## Functional Requirements
1. A `DemoBooking` model stores: `restaurant_name`, `contact_name`, `email`, `phone` (optional), `restaurant_type` (enum), `location_count`, `interests` (text), `calendly_event_id` (nullable), `conversion_status` (default: 'pending').
2. A `demo_bookings` table with indexes on `email` and `created_at`.
3. `DemoBookingsController#create` (JSON API): validates and saves the lead, sends confirmation email via `DemoBookingMailer`, returns a Calendly booking URL.
4. Calendly integration: generate a Calendly booking link with pre-filled contact data using the Calendly API or UTM-parameterised URL. No Calendly gem required for v1 — construct URL with query params.
5. `DemoBookingMailer#confirmation` sends a branded confirmation email (uses branded mailer layout from #2 if available, otherwise fallback styling) with: demo details, what to expect, and a calendar invitation link.
6. Recorded demo video: embed using `<video>` tag or a hosted video service (Vimeo/Loom). Tracks basic engagement events (play, pause, 75% completion) via Stimulus controller.
7. Homepage hero section: two CTAs — "Book Live Demo" and "Watch Demo". Both are prominently placed above the fold on desktop and mobile.
8. Video analytics events are logged to a `video_analytics` table: `video_id`, `session_id`, `event_type`, `timestamp_seconds`, `ip_address`, `created_at`.
9. No CRM integration required for v1 — `demo_bookings` table serves as the CRM. Export to CSV in admin.

## Non-Functional Requirements
- Form submits via Turbo/fetch — no full page reload.
- Confirmation email delivered within 60 seconds (background via Sidekiq `deliver_later`).
- No new JS frameworks — use Stimulus for video tracking and modal behaviour.
- GDPR: email collection requires privacy policy link adjacent to the form submit button.
- Rate-limit demo booking submissions: max 5 per IP per hour (Rack::Attack).

## Technical Notes

### Models / Migrations
- `create_demo_bookings`: `restaurant_name:string not null`, `contact_name:string not null`, `email:string not null`, `phone:string`, `restaurant_type:string`, `location_count:string`, `interests:text`, `calendly_event_id:string`, `conversion_status:string default:'pending'`.
- `create_video_analytics`: `video_id:string`, `session_id:string`, `event_type:string`, `timestamp_seconds:integer`, `ip_address:inet`, `user_agent:text`, `created_at:datetime`.
- Indexes: `demo_bookings` on `[email]`, `[created_at]`; `video_analytics` on `[video_id, created_at]`.

### Mailers
- `app/mailers/demo_booking_mailer.rb`: `confirmation(demo_booking)` — uses branded layout.

### Jobs
- No dedicated job — use `DemoBookingMailer.confirmation(demo_booking).deliver_later`.

### Controllers
- `app/controllers/demo_bookings_controller.rb`: `create` (JSON response), `video_analytics` (POST, logs event).
- No Pundit policy needed for public-facing creation. Admin view gated by existing admin auth.

### Views / JS
- `app/javascript/controllers/demo_booking_controller.js`: handles form submit, shows Calendly widget on success.
- `app/javascript/controllers/video_analytics_controller.js`: tracks video events, posts to `/demo_bookings/video_analytics`.
- Homepage partials: `_demo_booking_modal.html.erb`, `_video_demo_modal.html.erb`.

### Routes
```ruby
resources :demo_bookings, only: [:create] do
  collection { post :video_analytics }
end
```

### Flipper
- No flag needed — this is a public marketing feature.

## Acceptance Criteria
1. Submitting the demo booking form with valid data creates a `DemoBooking` record and returns a Calendly booking URL.
2. The prospect receives a branded confirmation email within 60 seconds.
3. The Calendly widget appears in the modal after successful form submission.
4. Submitting with invalid data (missing required fields) returns validation errors without creating a record.
5. The recorded demo video plays when the "Watch Demo" CTA is clicked.
6. A `video_analytics` record is created when the video reaches 75% completion.
7. More than 5 demo booking submissions from the same IP in an hour are rejected with a 429 response.
8. The form and video player are functional and usable on a 375px-wide mobile viewport.

## Out of Scope
- CRM integration (HubSpot, Salesforce) — post-launch.
- Lead scoring — post-launch.
- A/B testing different demo videos — post-launch.
- Automated follow-up email sequences — post-launch.
- Multi-language demo content — post-launch.

## Open Questions
1. Is the recorded demo video already produced? If not, this spec must be treated as dependent on video production — the booking form can ship without it.
2. Which Calendly account / event type should be used? Provide the Calendly event URL slug before development starts.
3. Should the "Book Demo" form appear on the main homepage, or on a dedicated `/demo` landing page? Recommended: both — inline section on homepage + standalone `/demo` page for direct link campaigns.
