# Two-Factor Authentication (2FA)

## Status
- Priority Rank: #27
- Category: Post-Launch
- Effort: M
- Dependencies: Devise 5 (already integrated), Redis (already active via Sidekiq)

## Problem Statement
Restaurant owner and staff accounts control payment configurations, menu pricing, and live orders. A compromised password alone is sufficient to cause financial harm to a restaurant. 2FA provides a second line of defence for accounts with elevated permissions, and is increasingly expected by enterprise or multi-location restaurant groups. It also supports PCI DSS posture for accounts that touch payment data.

## Success Criteria
- Restaurant owners and admins can enable TOTP-based 2FA from their account security settings
- Login flow prompts for OTP code after password validation when 2FA is enabled
- Backup codes are generated, hashed, and stored securely at setup time
- Staff members can optionally enable 2FA; platform admins can make it mandatory for specific roles
- 2FA adoption rate is visible in the mellow.menu admin panel
- OTP brute-force is prevented by lockout after configurable failed attempts

## User Stories
- As a restaurant owner, I want to enable 2FA on my account so that a stolen password alone cannot give attackers access to my restaurant data and payment settings.
- As a staff member, I want to set up 2FA optionally so that I can protect my login without requiring it.
- As a mellow.menu platform admin, I want to enforce 2FA for all admin-role employees across the platform so that we reduce account takeover risk.
- As any user, I want backup codes so that I can recover access if I lose my authenticator device.

## Functional Requirements
1. Users navigate to a Security Settings page within their account profile.
2. The system generates a TOTP secret using the `rotp` gem and displays it as a QR code (via `rqrcode`) for scan into any TOTP app (Google Authenticator, Authy, 1Password, etc.).
3. The user must verify one valid OTP code before 2FA is activated — this confirms the device is properly configured.
4. On successful verification, 10 single-use hashed backup codes are generated and displayed once.
5. The login flow, after successful Devise password validation, checks whether the user has 2FA enabled. If so, a second step is presented before the session is established.
6. OTP attempts are rate-limited: 5 failed attempts locks the second-factor step for 15 minutes (using Redis via Rack::Attack, which is already configured).
7. A "Trust this device" option sets a signed, long-lived cookie (30 days) that skips the OTP step on that specific device.
8. Backup codes can be regenerated from Security Settings (requires current password to confirm).
9. 2FA can be disabled from Security Settings (requires current password and one valid OTP or backup code to confirm).
10. Platform admins can view 2FA adoption per restaurant and per user in the admin panel.
11. Platform admins can enforce 2FA as mandatory for the `admin` role across all restaurants via a Flipper flag.

## Non-Functional Requirements
- OTP secret keys must be encrypted at rest (use Rails `encrypts` — already applied to PII fields on User).
- Backup codes must be hashed (bcrypt) before storage — never stored in plaintext.
- The trusted-device cookie must be signed with `Rails.application.secret_key_base`; mark `HttpOnly` and `Secure`.
- No new JS frameworks — use Hotwire Turbo for the two-step login flow and Stimulus for the OTP input auto-focus/auto-submit.
- The OTP entry screen must be accessible: visible focus state, clear error messaging, no CAPTCHA.
- GDPR: the `otp_secret_key` and backup codes constitute security credentials, not personal data — no additional disclosure required beyond existing privacy policy.

## Technical Notes

### Gems to add
```ruby
gem 'rotp', '~> 6.2'   # TOTP generation and validation
gem 'rqrcode', '~> 2.1' # QR code rendering to SVG
```

### Model: User
Add to the `users` migration (new columns, do not alter existing role/enum structure):
```ruby
add_column :users, :otp_secret_key, :string        # encrypted via Rails encrypts
add_column :users, :otp_enabled, :boolean, default: false, null: false
add_column :users, :otp_enabled_at, :datetime
add_column :users, :otp_backup_codes, :text         # JSON array of bcrypt hashes
add_column :users, :otp_failed_attempts, :integer, default: 0, null: false
add_column :users, :otp_locked_until, :datetime
add_index  :users, :otp_enabled
```

**Important**: roles live on the `Employee` model (`staff: 0, manager: 1, admin: 2`), not on `User`. The 2FA enforcement for "admin role" means employees whose `Employee#role == :admin`.

### Services to create
- `app/services/two_factor/setup_service.rb` — generates secret, returns QR SVG and setup URI
- `app/services/two_factor/verification_service.rb` — validates OTP or backup code, handles lockout logic
- `app/services/two_factor/backup_code_service.rb` — generates, hashes, and stores backup codes; validates and consumes on use

### Controller/routing
- Extend Devise's sessions flow: override `Sessions::OtpChallengeController` (custom controller) to insert the OTP step after password validation.
- The OTP challenge uses Turbo Frames so the login page updates inline without a full redirect.
- `Users::SecurityController` for setup/disable actions (Pundit: `UserPolicy#manage_security?` — own account only, or platform admin).

### Pundit policy
Add `app/policies/user_policy.rb` methods:
- `manage_two_factor?` — user is current_user (own account) or platform admin
- Do not add role-escalation logic here — roles are on `Employee`, not `User`

### Flipper flags
- `two_factor_auth` — master switch; gates the Security Settings UI and the login challenge
- `two_factor_enforcement` — when enabled, forces admin-role employees to complete 2FA setup before accessing the back office

### Rack::Attack (already configured)
Add throttle for OTP attempts:
```ruby
throttle('otp/ip', limit: 10, period: 10.minutes) { |req| req.ip if req.path == '/users/otp_challenge' }
```

### No LoginAttempt model needed in v1
The existing Devise `:lockable` and `:session_limitable` modules already handle login attempt tracking. Extend those rather than creating a parallel `LoginAttempt` table.

### No TrustedDevice model needed in v1
Use a signed cookie with a UUID fingerprint. Store the fingerprint in Redis (via existing connection) with a 30-day TTL, associated with the user ID. Avoids a new table for v1.

## Acceptance Criteria
1. A user with 2FA disabled can log in with email + password in exactly the same number of steps as today.
2. A user with 2FA enabled is presented with an OTP input field after correct password entry, and cannot access the application without providing a valid code.
3. A valid TOTP code (within the 30-second window, ±1 step drift) succeeds.
4. An invalid code increments `otp_failed_attempts` and returns an error; after 5 consecutive failures the account is locked for 15 minutes and an appropriate message is shown.
5. A valid backup code succeeds and is immediately invalidated (cannot be reused).
6. A trusted device (cookie present and valid in Redis) skips the OTP step on subsequent logins within the 30-day window.
7. Disabling 2FA requires the correct current password AND a valid OTP or backup code.
8. Regenerating backup codes invalidates all previous backup codes.
9. The `two_factor_enforcement` Flipper flag, when enabled, redirects admin-role employees to the 2FA setup page after login until setup is complete.
10. The `otp_secret_key` column value is unreadable plaintext in a direct database query (encrypted at rest).

## Out of Scope
- SMS-based OTP (Twilio not yet integrated; TOTP apps are the v1 delivery mechanism)
- Hardware security key (FIDO2/WebAuthn) support
- Admin-initiated 2FA recovery on behalf of users (v1: users self-recover via backup codes or contact support)
- Audit log of login attempts beyond what Devise `:lockable` already provides
- Per-device login history UI

## Open Questions
1. Should `manager`-role employees also be subject to the `two_factor_enforcement` flag, or only `admin`? Recommend admin-only in v1.
2. What is the lockout duration for OTP brute-force? Spec assumes 15 minutes — confirm with product.
3. Is the 30-day trusted-device window acceptable, or should it be shorter for security-sensitive accounts?
