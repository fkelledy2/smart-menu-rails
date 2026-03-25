# Branded Receipt Email & SMS Delivery

## Status
- Priority Rank: #3
- Category: Launch Blocker
- Effort: M
- Dependencies: Branded Email Styling (#2), Payments::Orchestrator (Stripe), existing Ordr model

## Problem Statement
When a customer pays for an order through mellow.menu, they receive no digital receipt. This is a critical gap: customers expect proof of purchase, restaurants need to demonstrate professional operation, and in many jurisdictions a receipt is a legal requirement for VAT/tax compliance. Without receipts, restaurants cannot confidently replace paper POS systems with mellow.menu. This feature closes the payment loop.

## Success Criteria
- Staff can send a branded email or SMS receipt to a customer's contact details from the order management view.
- Customers can self-request a receipt from the SmartMenu interface after payment.
- Receipt contains: restaurant name/logo, order number, itemised list, subtotal, tax, tip, total, date/time, payment method.
- Email delivery succeeds for 98%+ of valid addresses.
- SMS delivery (via Twilio or equivalent) is implemented as a stretch goal within this spec.
- GDPR-compliant: contact data is collected with explicit consent and stored securely.

## User Stories
- As a customer, I want to receive a branded digital receipt by email so I have a record of my purchase.
- As a staff member, I want to send a receipt from the order management screen in two taps.
- As a customer, I want to request my own receipt from the SmartMenu after paying.
- As a restaurant owner, I want receipts to carry my restaurant's logo and name.

## Functional Requirements
1. A `ReceiptDeliveryService` accepts an `Ordr`, contact info (email and/or phone), and delivery method, and dispatches the receipt.
2. A `ReceiptMailer#customer_receipt` mailer sends a branded HTML + plain-text email using the shared branded layout (see #2).
3. The email receipt includes: restaurant name, logo, address, order number, itemised `Ordritem` list (name, quantity, unit price, line total), subtotal, tax, tip, grand total, date, and a "Thank you" footer.
4. Staff UI: an "Email Receipt" button appears on the order detail view (kitchen/station dashboard or order management) once an order is in `paid` or `closed` status.
5. Staff can enter customer email (and optionally phone) in a modal and send the receipt.
6. Customer self-service: a "Get Receipt" option appears in the SmartMenu order view after payment, allowing the customer to enter their email and request a receipt.
7. A `receipt_deliveries` table tracks: `ordr_id`, `recipient_email`, `recipient_phone`, `delivery_method`, `status` (pending/sent/failed), `sent_at`, `error_message`, `retry_count`, `created_by_user_id`.
8. Failed deliveries are retried up to 3 times via Sidekiq with exponential backoff (`ReceiptDeliveryJob`).
9. Receipt content is rendered from a shared template with restaurant-specific values injected (logo URL, name, address).
10. SMS receipt (stretch): sends a short message with a link to a web receipt page (`/receipts/:token`). Requires `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_FROM_NUMBER` env vars.

## Non-Functional Requirements
- No raw PAN or payment data is included in receipts — only last-4 digits of card if available from Stripe response.
- Contact data stored in `receipt_deliveries` must be accessed only by authorised staff/admin (Pundit policy).
- Email delivery must use the existing ActionMailer + Sidekiq (`deliver_later`) pipeline.
- Statement timeouts apply.
- GDPR: contact data collected via self-service form must include explicit consent checkbox and must not be used for marketing without separate opt-in.

## Technical Notes

### Services
- `app/services/receipt_delivery_service.rb`: orchestrates receipt generation and dispatch. Does not call Stripe directly.
- `app/services/receipt_template_renderer.rb`: renders HTML/text receipt from `Ordr` data.

### Mailers
- `app/mailers/receipt_mailer.rb`: `customer_receipt(receipt_delivery:)` — uses branded mailer layout.

### Jobs
- `app/jobs/receipt_delivery_job.rb`: Sidekiq job with retry logic for failed deliveries.

### Models / Migrations
- `create_receipt_deliveries` migration: `ordr_id:bigint`, `recipient_email:string`, `recipient_phone:string`, `delivery_method:string`, `status:string default:'pending'`, `sent_at:datetime`, `error_message:text`, `retry_count:integer default:0`, `created_by_user_id:bigint`.
- No changes to `Ordr` model required.

### Policies
- `app/policies/receipt_delivery_policy.rb`: staff and managers can create; admin can view all.

### Controllers
- `app/controllers/receipt_deliveries_controller.rb`: `create` action (staff), `self_service` action (customer-facing, rate-limited).

### Views
- `app/views/receipt_mailer/customer_receipt.html.erb` and `.text.erb`.
- Staff modal partial: `app/views/ordrs/_send_receipt_modal.html.erb` (Turbo frame).
- SmartMenu customer receipt request form (Stimulus controller: `receipt_request_controller.js`).

### Flipper
- `receipt_email` — enable per restaurant before global rollout.
- `receipt_sms` — separate flag for SMS stretch goal.

## Acceptance Criteria
1. Staff clicking "Email Receipt" on a paid order opens a modal, enters a customer email, and clicking "Send" enqueues `ReceiptDeliveryJob`.
2. The customer receives an email within 60 seconds containing all required receipt fields.
3. The email uses the branded layout (logo, restaurant name, colour scheme).
4. A `receipt_deliveries` record is created with `status: 'sent'` and `sent_at` populated on success.
5. If delivery fails, `status` is set to `'failed'`, `error_message` is populated, and the job retries up to 3 times.
6. A customer submitting the self-service receipt form on SmartMenu triggers the same delivery path.
7. No payment card numbers appear in the receipt email body.
8. `ReceiptDeliveryPolicy` prevents non-staff users from accessing the staff-side send endpoint.

## Out of Scope
- PDF receipt generation (post-launch — email HTML is sufficient for v1).
- Receipt template customisation per restaurant (post-launch).
- Bulk receipt resend (post-launch).
- Marketing opt-in from the receipt form (post-launch).
- Digital wallet integration (Apple/Google Wallet) — post-launch.

## Open Questions
1. Which field on the `Ordr` model stores the payment method / last 4 digits from Stripe? Confirm before building the renderer.
2. Does the restaurant model have a `logo_url` or equivalent for use in receipt emails? Check `Restaurant` model for logo attachment (ActiveStorage or Cloudinary).
3. Is Twilio already integrated, or does SMS require a new provider setup? Check existing services for any SMS infrastructure.
4. Should the self-service receipt form appear before or after payment confirmation in the SmartMenu flow?
