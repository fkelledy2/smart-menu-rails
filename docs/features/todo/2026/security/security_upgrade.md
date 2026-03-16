# Security Gems Upgrade Requirements

## Current Status

### ✅ Implemented (3/7)
- brakeman v6.0+ (static scanner)
- bundler-audit v0.9+ (CVE checker)
- rack-attack (rate limiting - configured in config/initializers/rack_attack.rb)

### ❌ Missing (4/7)

#### High Priority
1. **devise-security** - Password policies, session limits, account locking
2. **active_storage_validations** - File upload validation (5 models use attachments)

#### Medium Priority  
3. **secure_headers** - HSTS, CSP, security headers
4. **invisible_captcha** - Honeypot bot protection

## Implementation Plan

### Phase 1: Critical (Week 1)

**devise-security v0.18**
- Password expiry: 90 days
- Password history: 5
- Session timeout: 30min
- Max sessions: 3
- Lock after 5 fails

**active_storage_validations v1.3**
- Menu: images, 10MB max
- MenuSource: PDF/HTML, 50MB
- OcrMenuImport: PDF, 50MB
- User: avatar, 5MB
- VoiceCommand: audio, 10MB

### Phase 2: Enhanced (Week 2)

**secure_headers v6.7**
- HSTS enabled
- CSP configured
- X-Frame-Options: DENY

**invisible_captcha v2.3**
- User registration
- Contact forms
- Restaurant submissions

## Success Metrics
- File upload vulnerabilities: 0
- Password compliance: 100%
- Security headers: A+
- Bot signups: -80%

## Rollout
1. Dev/test install
2. Full test suite
3. Staging deploy
4. 48hr monitor
5. Production with flags
6. 1 week monitor
