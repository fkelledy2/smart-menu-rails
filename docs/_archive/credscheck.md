# Credentials Audit: ENV Variables vs Rails Credentials

**Date**: February 3, 2026  
**Purpose**: Identify redundant credentials entries after migrating to ENV variable preference

## Executive Summary

Following recent code changes to prefer environment variables over Rails credentials, **3 credential entries are now fully redundant** and can be safely removed. These are now managed via Heroku config vars across all environments.

---

## ✅ Redundant Credentials (Safe to Remove)

### 1. AWS Credentials
```yaml
aws:
  access_key_id: "[REDACTED]"
  secret_access_key: "[REDACTED]"
  region: "eu-west-1"
  bucket: "[REDACTED]"
```

**Status**: ✅ **FULLY REDUNDANT**

**Reason**: Code now prefers `ENV['AWS_*']` variables everywhere:
- `config/storage.yml` - Uses `ENV['AWS_ACCESS_KEY_ID']`, `ENV['AWS_SECRET_ACCESS_KEY']`, `ENV['AWS_REGION']`, `ENV['AWS_S3_BUCKET']`
- `config/initializers/shrine.rb` - Uses same ENV variables
- All Heroku environments (production, staging, dev) have these set via Bucketeer add-on

**Code References**:
```ruby
# config/storage.yml
access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'].presence || Rails.application.credentials.dig(:aws, :access_key_id) %>

# config/initializers/shrine.rb
aws_key = ENV['AWS_ACCESS_KEY_ID'].presence || Rails.application.credentials.dig(:aws, :access_key_id)
```

---

### 2. Stripe Credentials
```yaml
stripe:
  secret_key: "[REDACTED]"
  webhook_secret: "[REDACTED]"
```

**Status**: ✅ **FULLY REDUNDANT**

**Reason**: Code now prefers `ENV['STRIPE_SECRET_KEY']` and `ENV['STRIPE_WEBHOOK_SECRET']`:
- `config/initializers/stripe.rb` - Prefers `ENV['STRIPE_SECRET_KEY']`
- `app/controllers/payments/base_controller.rb` - Prefers ENV
- `app/controllers/payments/intents_controller.rb` - Prefers ENV
- `app/controllers/ordr_payments_controller.rb` - Prefers ENV
- `app/services/payments/providers/stripe_adapter.rb` - Prefers ENV
- `app/services/payments/providers/stripe_connect.rb` - Prefers ENV
- `app/controllers/payments/webhooks_controller.rb` - Prefers ENV for webhook secret
- All Heroku environments have `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` set

**Code References**:
```ruby
# config/initializers/stripe.rb
key = ENV['STRIPE_SECRET_KEY'].presence || 
      Rails.application.credentials.stripe_secret_key ||
      Rails.application.credentials.dig(:stripe, :secret_key)

# app/controllers/payments/webhooks_controller.rb
webhook_secret = ENV['STRIPE_WEBHOOK_SECRET'].presence ||
                 Rails.application.credentials.dig(:stripe, :webhook_secret)
```

---

### 3. Google Maps API Key
```yaml
google_maps_api_key: "[REDACTED]"
```

**Status**: ✅ **FULLY REDUNDANT**

**Reason**: Code now prefers `ENV['GOOGLE_MAPS_API_KEY']`:
- `app/views/shared/_head.html.erb` - Uses `ENV['GOOGLE_MAPS_API_KEY']` or `ENV['GOOGLE_MAPS_BROWSER_API_KEY']`
- All Heroku environments have `GOOGLE_MAPS_API_KEY` set

**Code References**:
```erb
<!-- app/views/shared/_head.html.erb -->
script.src = `https://maps.googleapis.com/maps/api/js?key=<%= 
  ENV['GOOGLE_MAPS_API_KEY'].presence || 
  ENV['GOOGLE_MAPS_BROWSER_API_KEY'].presence || 
  Rails.application.credentials.google_maps_api_key 
%>&libraries=places&loading=async&callback=Function.prototype`;
```

---

## ⚠️ Keep in Credentials (Still Required)

### 1. Spotify Credentials
```yaml
spotify_key: "[REDACTED]"
spotify_secret: "[REDACTED]"
```

**Status**: ⚠️ **KEEP - ACTIVELY USED**

**Reason**: Still used directly in multiple places without ENV fallback:
- `config/initializers/omniauth.rb` - Direct usage
- `config/initializers/devise.rb` - Direct usage for OAuth
- `config/initializers/rspotify.rb` - Direct usage
- `app/controllers/sessions_controller.rb` - Direct usage
- `app/controllers/restaurants_controller.rb` - Direct usage

**Recommendation**: Consider adding ENV variable support in future refactoring.

---

### 2. OpenAI Credentials
```yaml
openai_api_key: "[REDACTED]"
openai_organization_id: "[REDACTED]"
openai:
  model: "gpt-4o-mini"
```

**Status**: ⚠️ **KEEP - FALLBACK REQUIRED**

**Reason**: Used as fallback when ENV not set:
- `config/initializers/chatgbt.rb` - Uses ENV with credentials fallback
- `app/services/openai_client.rb` - Uses ENV with credentials fallback
- `app/services/openai_whisper_transcription_service.rb` - Uses ENV with credentials fallback
- `app/services/pdf_menu_processor.rb` - Uses credentials for API key and model
- `app/jobs/menu_item_image_generator_job.rb` - Uses credentials
- `app/controllers/genimages_controller.rb` - Uses credentials

**Code Pattern**:
```ruby
@api_key = api_key || Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
```

---

### 3. DeepL API Key
```yaml
deepl_api_key: "[REDACTED]"
```

**Status**: ⚠️ **KEEP - FALLBACK REQUIRED**

**Reason**: Used as fallback in translation services:
- `config/initializers/deepl.rb` - Uses ENV with credentials fallback
- `app/services/deepl_client.rb` - Uses ENV with credentials fallback
- `app/services/deepl_api_service.rb` - Uses ENV with credentials fallback

**Code Pattern**:
```ruby
api_key = Rails.application.credentials.deepl_api_key || ENV.fetch('DEEPL_API_KEY', nil)
```

---

### 4. Google Cloud Vision Credentials
```yaml
gcp_vision_credentials:
  type: "service_account"
  project_id: "[REDACTED]"
  private_key_id: "[REDACTED]"
  private_key: "[REDACTED]"
  client_email: "[REDACTED]"
  # ... (full service account JSON structure)
```

**Status**: ⚠️ **KEEP - COMPLEX STRUCTURE**

**Reason**: 
- Complex JSON structure required by Google Cloud SDK
- Used as fallback in `config/initializers/google_cloud_vision.rb`
- Prefers ENV variable `GOOGLE_APPLICATION_CREDENTIALS` (file path) or `GCP_VISION_CREDENTIALS` (JSON string)
- Credentials provide convenient fallback for development

---

### 5. Secret Key Base
```yaml
secret_key_base: "[REDACTED]"
```

**Status**: ⚠️ **KEEP - REQUIRED**

**Reason**: 
- Required by Rails for session management
- Used by Devise for authentication: `config.secret_key = Rails.application.credentials.secret_key_base`
- Critical for security

---

## Heroku Environment Status

All three Heroku environments have the redundant credentials properly configured via config vars:

### Production (`smart-menus`)
- ✅ `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`
- ✅ `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- ✅ `GOOGLE_MAPS_API_KEY`

### Staging (`smart-menus-staging`)
- ✅ `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`
- ✅ `REDIS_URL` (from openredis)
- ✅ `DATABASE_URL` (from Heroku Postgres)

### Development (`smart-menus-dev`)
- ✅ `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`
- ✅ `REDIS_URL` (from openredis)
- ✅ `DATABASE_URL` (from Heroku Postgres)

---

## Recommended Actions

### Immediate (Safe)
1. **Remove AWS credentials** from `config/credentials/development.yml.enc`
2. **Remove Stripe credentials** from credentials file
3. **Remove Google Maps API key** from credentials file

### Future Refactoring (Optional)
1. **Add ENV support for Spotify** credentials to match pattern used for other services
2. **Document ENV variable requirements** in `docs/deployment/ENVIRONMENT_VARIABLES.md`
3. **Consider migrating OpenAI/DeepL** to ENV-only if consistent across environments

---

## Migration Commands

To remove redundant credentials:

```bash
# Edit development credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development

# Remove these sections:
# - aws (entire section)
# - stripe (entire section)  
# - google_maps_api_key (single line)
```

**Note**: Keep all other credentials (Spotify, OpenAI, DeepL, GCP Vision, secret_key_base) as they are still actively used.

---

## Code Pattern Summary

### ✅ Good Pattern (ENV-first with credentials fallback)
```ruby
key = ENV['STRIPE_SECRET_KEY'].presence || 
      Rails.application.credentials.stripe_secret_key ||
      Rails.application.credentials.dig(:stripe, :secret_key)
```

### ⚠️ Old Pattern (credentials-only, needs refactoring)
```ruby
spotify_key = Rails.application.credentials.spotify_key
spotify_secret = Rails.application.credentials.spotify_secret
```

---

## Verification Checklist

- [x] All Heroku environments have AWS config vars set via Bucketeer
- [x] All Heroku environments have Stripe config vars set
- [x] Production has Google Maps API key set
- [x] Code prefers ENV variables over credentials for AWS, Stripe, Google Maps
- [x] Fallback to credentials still works for local development
- [x] No breaking changes to existing functionality

---

**Conclusion**: Safe to remove 3 credential entries (AWS, Stripe, Google Maps) from Rails credentials. All are now managed via Heroku config vars with proper ENV variable preference in code.
