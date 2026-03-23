# Two-Factor Authentication (2FA) Support

## Overview
Implement two-factor authentication for mellow.menu users to enhance account security and protect sensitive restaurant data and financial information.

## Business Value
- **Security**: Protects against unauthorized access to restaurant accounts
- **Compliance**: Meets modern security standards for financial transactions
- **Trust**: Builds confidence with restaurant owners handling payments
- **Risk reduction**: Mitigates damage from password breaches

## User Stories

### Restaurant Owner/Admin
- As a restaurant owner, I want to enable 2FA on my account to protect sensitive business data
- As a restaurant owner, I want backup codes in case I lose access to my 2FA device
- As a restaurant owner, I want to see which devices are logged into my account
- As a restaurant owner, I want to receive notifications for new login attempts

### Staff User
- As a staff member, I want to use 2FA to protect my access to restaurant systems
- As a staff member, I want an easy setup process for 2FA on my mobile device
- As a staff member, I want to be able to trust this device for convenience

### System Administrator
- As a system admin, I want to enforce 2FA for certain user roles
- As a system admin, I want to monitor 2FA adoption across the platform
- As a system admin, I want to help users recover from lost 2FA devices

## Technical Requirements

### Data Model Changes

#### User Model
```ruby
# New fields
add_column :users, :otp_secret_key, :string
add_column :users, :otp_enabled, :boolean, default: false
add_column :users, :otp_backup_codes, :text, array: true
add_column :users, :otp_enabled_at, :datetime
add_column :users, :otp_failed_attempts, :integer, default: 0
add_column :users, :otp_locked_until, :datetime

# Indexes
add_index :users, :otp_secret_key, unique: true
```

#### TrustedDevice Model (New)
```ruby
create_table :trusted_devices do |t|
  t.references :user, null: false, foreign_key: true
  t.string :device_fingerprint, null: false
  t.string :user_agent
  t.string :ip_address
  t.datetime :last_used_at
  t.datetime :expires_at
  t.timestamps
  
  t.index [:user_id, :device_fingerprint], unique: true
end
```

#### LoginAttempt Model (New)
```ruby
create_table :login_attempts do |t|
  t.references :user, foreign_key: true
  t.string :ip_address
  t.string :user_agent
  t.string :device_fingerprint
  t.boolean :success
  t.string :failure_reason
  t.datetime :created_at
  
  t.index :ip_address
  t.index :created_at
end
```

### Gem Dependencies
```ruby
# Gemfile
gem 'rotp', '~> 6.2'  # Time-based OTP
gem 'rqrcode', '~> 2.1'  # QR code generation
```

### Authentication Flow

#### Initial Setup
1. User navigates to Security Settings
2. Generate OTP secret key
3. Display QR code for authenticator apps
4. Verify user can generate valid codes
5. Show backup codes
6. Enable 2FA

#### Login Flow with 2FA
1. User enters email/password
2. If 2FA enabled, show OTP verification screen
3. User enters 6-digit code
4. Validate code and authenticate
5. Offer "Trust this device" option

#### Backup Code Flow
1. User selects "Can't access your authenticator?"
2. Enter backup code
3. Validate and consume backup code
4. Force password change and 2FA re-setup

### API Changes

#### Authentication Endpoints
```ruby
# POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password",
  "otp_attempt": "123456",  # Optional, required if 2FA enabled
  "trust_device": true       # Optional
}

# Response
{
  "user": { ... },
  "token": "jwt_token",
  "requires_otp": false,
  "otp_remaining_attempts": 3
}
```

#### 2FA Management Endpoints
```ruby
# POST /api/v1/auth/2fa/setup
# Response: { secret: "BASE32_SECRET", qr_code: "data:image/png;base64,..." }

# POST /api/v1/auth/2fa/verify
# Body: { code: "123456" }

# DELETE /api/v1/auth/2fa/disable
# Body: { password: "current_password" }

# GET /api/v1/auth/2fa/backup_codes
# Response: { codes: ["12345678", "87654321", ...] }

# POST /api/v1/auth/2fa/regenerate_backup_codes
# Body: { password: "current_password" }
```

### UI/UX Requirements

#### Security Settings Page
- Enable/disable 2FA toggle
- QR code display for setup
- Backup codes management
- Trusted devices list
- Recent login activity

#### Login Screen Enhancements
- OTP input field (6 digits)
- Backup code option
- "Trust device" checkbox
- Clear error messages
- Help links and support

#### Mobile Experience
- Responsive OTP input
- Easy copy/paste for codes
- Auto-focus management
- Keyboard-friendly navigation

### Security Considerations

#### Rate Limiting
- Limit OTP attempts (max 5 per session)
- Lock account after failed attempts
- IP-based rate limiting for brute force protection

#### Backup Code Security
- Generate cryptographically secure codes
- Hash stored backup codes
- Single-use codes
- Minimum length (8 characters)

#### Session Security
- Short-lived sessions for untrusted devices
- Device fingerprinting
- IP change detection
- Concurrent session limits

#### Recovery Process
- Email verification for account recovery
- Admin override capability
- Audit trail for all recovery actions
- Temporary password with forced change

### Implementation Phases

#### Phase 1: Core 2FA Implementation
1. Database migrations
2. OTP generation and validation
3. Basic login flow integration
4. QR code generation

#### Phase 2: User Interface
1. Security settings page
2. Enhanced login screen
3. Backup code management
4. Mobile responsiveness

#### Phase 3: Advanced Features
1. Trusted device management
2. Login attempt tracking
3. Admin enforcement tools
4. Recovery workflows

#### Phase 4: Monitoring & Analytics
1. 2FA adoption metrics
2. Security event logging
3. Admin dashboard
4. Compliance reporting

### Testing Requirements

#### Unit Tests
- OTP generation and validation
- Backup code generation and consumption
- Rate limiting logic
- Device fingerprinting

#### Integration Tests
- Complete authentication flows
- API endpoint security
- Database constraints
- Email notifications

#### System Tests
- End-to-end user journeys
- Mobile device testing
- Accessibility compliance
- Performance under load

### Performance Considerations
- Efficient OTP validation (avoid database hits)
- Cached device fingerprints
- Minimal impact on login speed
- Scalable backup code storage

### Compliance & Standards
- OWASP authentication guidelines
- GDPR compliance for personal data
- PCI DSS considerations for payment processing
- Audit trail requirements

### Dependencies
- External authenticator apps (Google Authenticator, Authy)
- Email delivery for backup codes
- Redis for rate limiting (optional)
- Monitoring for security events

### Rollout Strategy
1. Optional 2FA for early adopters
2. Encourage adoption through notifications
3. Required for admin accounts
4. Required for all users with payment access
5. Platform-wide enforcement
