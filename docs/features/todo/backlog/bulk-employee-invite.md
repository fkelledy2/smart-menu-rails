# Bulk Employee Invitation

## Status
- Priority Rank: #28
- Category: Post-Launch
- Effort: M
- Dependencies: `StaffInvitation` model (already exists), `StaffInvitationMailer` (already exists), Sidekiq (already active), Active Storage (already configured)

## Problem Statement
Restaurant managers onboarding a new team — particularly for seasonal hires, new location openings, or franchise rollouts — must currently invite each staff member individually. With a team of 20+ employees, this becomes a time-consuming, error-prone manual process. A bulk invitation flow (CSV upload or spreadsheet-like manual entry) that builds on the existing `StaffInvitation` model reduces onboarding friction and gets new restaurants live faster.

## Success Criteria
- A restaurant admin or manager can upload a CSV file and have it parsed into a preview list of invitations before sending
- Validation errors (bad email format, duplicate emails, unknown role) are reported per row before any invitations are sent
- Invitations are sent in a background job — the UI does not block waiting for email delivery
- A progress/status view shows how many invitations are pending, sent, accepted, or failed
- The manager can re-send any failed or expired invitations without re-entering data
- CSV template is downloadable from the invite UI

## User Stories
- As a restaurant admin opening a new location, I want to upload a CSV of 30 new hires and send invitations to all of them in a single action, so I can onboard the team in minutes rather than an hour.
- As a restaurant manager, I want to see which invitations are still pending after a week so I can follow up with staff who haven't registered.
- As an invited employee, I want to receive a clear invitation email using the same branded template I'd get from a single invite, so the experience feels consistent.
- As a mellow.menu platform admin, I want to see bulk invitation usage across restaurants so I can identify volume abuse and set appropriate limits.

## Functional Requirements
1. A "Bulk Invite" entry point appears alongside the existing single-invite form in the staff management section, gated by the `bulk_employee_invite` Flipper flag.
2. CSV upload accepts a file with the following columns: `first_name`, `last_name`, `email`, `role` (optional, defaults to `staff`). Any additional columns are ignored.
3. CSV processing happens synchronously for files up to 200 rows (fast enough for a web request); files over 200 rows are processed via `ProcessBulkInvitationCsvJob`.
4. Before sending, the UI renders a preview table of parsed rows. Rows with validation errors are highlighted with specific error messages. The user can correct and re-upload or remove invalid rows.
5. On confirmation, a `BulkInvitation` record is created and `SendBulkInvitationJob` is enqueued to send each individual `StaffInvitation` and deliver the email.
6. The existing `StaffInvitationMailer` and email template are reused — no new email template is needed for bulk invites.
7. Each bulk invitation item links to the `StaffInvitation` record created for it, so acceptance tracking flows through the existing invitation system.
8. A bulk invitation dashboard shows: total sent, accepted count, pending count, failed count, and a per-row status table.
9. Managers can re-send any individual invitation that has status `pending`, `expired`, or `failed` via a single button — this creates a new `StaffInvitation` with a fresh token and expiry.
10. The system prevents sending invitations to email addresses that already have an active `Employee` record at the same restaurant.

## Non-Functional Requirements
- CSV files are virus-scanned or at minimum validated for MIME type and extension before processing (use Active Storage validation, same pattern as avatar upload on User).
- CSV injection is prevented: any cell value beginning with `=`, `+`, `-`, or `@` is sanitised before display.
- Maximum CSV file size: 1MB. Maximum rows per batch: 500.
- All email delivery happens via Sidekiq — never blocking the web request.
- UI is Hotwire Turbo/Stimulus — no React or new JS framework.
- Rack::Attack rate limit: max 5 bulk invitation batches per restaurant per hour.

## Technical Notes

### New model: BulkInvitation
```ruby
create_table :bulk_invitations do |t|
  t.references :restaurant,   null: false, foreign_key: true
  t.references :created_by,   null: false, foreign_key: { to_table: :employees }
  t.string     :status,       null: false, default: 'draft'
  # status enum: draft, sending, completed, completed_with_errors, failed
  t.integer    :total_count,  null: false, default: 0
  t.integer    :sent_count,   default: 0
  t.integer    :accepted_count, default: 0
  t.integer    :failed_count, default: 0
  t.timestamps
  t.index :restaurant_id
  t.index :status
end
```

### New model: BulkInvitationItem
```ruby
create_table :bulk_invitation_items do |t|
  t.references :bulk_invitation,  null: false, foreign_key: true
  t.references :staff_invitation,             foreign_key: true   # nil until sent
  t.string     :first_name,       null: false
  t.string     :last_name,        null: false
  t.string     :email,            null: false
  t.integer    :role,             null: false, default: 0         # mirrors StaffInvitation role enum
  t.string     :status,           null: false, default: 'pending'
  # status: pending, sent, accepted, expired, failed
  t.text       :error_message
  t.datetime   :sent_at
  t.datetime   :accepted_at
  t.timestamps
  t.index :bulk_invitation_id
  t.index :email
  t.index :status
end
```

**Do NOT** add a `bulk_invitation_item_id` foreign key to `StaffInvitation` in v1 — use the reverse relationship (`BulkInvitationItem belongs_to :staff_invitation`) to avoid a migration on the existing invitations table.

### Services
- `app/services/employees/bulk_invitation_csv_parser_service.rb` — parses CSV, returns array of parsed row hashes and array of per-row error hashes. Does not touch the database.
- `app/services/employees/bulk_invitation_dispatch_service.rb` — iterates `BulkInvitationItem` records, calls the existing `StaffInvitation` creation path, delivers email via `StaffInvitationMailer`, updates item status.

### Background jobs
- `app/jobs/process_bulk_invitation_csv_job.rb` — for large CSV files (>200 rows); updates the `BulkInvitation` with parsed items via Turbo Stream broadcast
- `app/jobs/send_bulk_invitation_job.rb` — processes all pending items for a given `BulkInvitation`; reports progress via ActionCable broadcast to the dashboard view

### Pundit policy
New `app/policies/bulk_invitation_policy.rb`:
- `create?` — employee is `manager?` or `admin?` at the restaurant
- `view?` — same
- `resend?` — same, and item status is `pending`, `expired`, or `failed`

### Flipper flag
- `bulk_employee_invite` — gates the entire feature; safe rollout

### CSV template endpoint
A simple controller action streams a static CSV template with headers and one example row. No service needed — just `send_data`.

### Reuse pattern
The CSV parsing service follows the same pattern as the existing menu OCR import (`OcrMenuImportService`) — parse, validate, preview, confirm, enqueue. Reuse that UX pattern for consistency.

## Acceptance Criteria
1. A manager uploads a valid 10-row CSV; the preview table shows all 10 rows with no errors.
2. A CSV with 3 rows containing invalid email formats shows those 3 rows highlighted with "Invalid email format"; valid rows can still be sent without the invalid ones.
3. A CSV row with a `role` value not in `[staff, manager, admin]` is rejected with "Invalid role" and not included in the batch.
4. A CSV row with an email that belongs to an existing active employee at the same restaurant is rejected with "Employee already exists".
5. Confirming a 10-row batch with no errors creates one `BulkInvitation` and 10 `BulkInvitationItem` records, all with status `pending`.
6. After `SendBulkInvitationJob` runs, each item transitions to `sent` and a corresponding `StaffInvitation` record exists. Email delivery is enqueued in Sidekiq.
7. The bulk invitation dashboard shows correct counts for sent, accepted, and failed items, updating without a full page reload via Turbo Streams.
8. Re-sending an expired item creates a new `StaffInvitation` with a new token and the item returns to `sent` status.
9. Uploading a file over 1MB is rejected at the controller with a flash error before any processing occurs.
10. Uploading a non-CSV file (e.g. `.xlsx`) is rejected with "File must be a CSV".

## Out of Scope
- Scheduled/delayed bulk sends (send now only in v1)
- Role-based invitation templates or custom invitation message per batch
- Analytics dashboard beyond the per-batch status table
- Department assignment (the `Employee` model does not currently have a department field)

## Open Questions
1. Should the "Bulk Invite" feature be restricted to plan tiers (e.g. Pro and above)? Recommend gating via Flipper to start, then move to plan tier after measuring adoption.
2. What is the maximum acceptable batch size? Spec assumes 500 rows — confirm with product/infra.
3. Should managers be able to invite other managers in bulk, or only staff? The raw spec allows it — confirm whether this is the intended behaviour or whether admin-only should be required for bulk manager invites.
