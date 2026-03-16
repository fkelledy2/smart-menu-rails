# Security Gems Upgrade Requirements

## Current Status

### Implemented (3/7)
- [x] **brakeman** v6.0+ - Static scanner
- [x] **bundler-audit** v0.9+ - CVE checker
- [x] **rack-attack** - Rate limiting (configured in config/initializers/rack_attack.rb)

### Missing (4/7)

#### High Priority
- [ ] **devise-security** - Password policies, session limits, account locking
- [ ] **active_storage_validations** - File upload validation (5 models use attachments)

#### Medium Priority  
- [ ] **secure_headers** - HSTS, CSP, security headers
- [ ] **invisible_captcha** - Honeypot bot protection

## Implementation Plan

### Phase 1: Critical (Week 1)

**devise-security v0.18**
- [ ] Install gem
- [ ] Password expiry: 90 days
- [ ] Password history: 5
- [ ] Session timeout: 30min
- [ ] Max sessions: 3
- [ ] Lock after 5 fails

**active_storage_validations v1.3**
- [ ] Install gem
- [ ] Menu: images, 10MB max
- [ ] MenuSource: PDF/HTML, 50MB
- [ ] OcrMe- [ ] OcrMe- [ ] OcrMe- [ ] OcrMe- [ ] OcrMe- [ ] OcrMe- [ ] OcrMedio, 10MB

### Phase 2: Enhanced (Week 2)

**secure_headers v6.7**
- [ ] Install gem
- [ ] HSTS enabled
- [ ] CSP configured
- [ ] X-Frame-Options: DENY

**invisible_captcha v2.3**
- [ ] Install gem
- [ ] User registration
- [ ] Contact forms
- [ ] Restaurant submissions

## Success Metrics
- [ ] File upload vulnerabilities: 0
- [ ] Password compliance: 100%
- [ ] Security headers: A+
- [ ] Bot signups: -80%

## Rollout
- [ ] Dev/test install
- [ ] Full test suite
- [ ] Staging deploy
- [ ] 48hr monitor
- [ ] Production with flags
- [ ] 1 week monitor
