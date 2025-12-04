# Social Sign-In (Google & Apple)

This guide explains how to add “Sign in with Google” and “Sign in with Apple” using Devise + OmniAuth.

## Overview
- Auth stack: Devise + OmniAuth 2.x
- Providers:
  - Google: `omniauth-google-oauth2`
  - Apple: `omniauth-apple`
- CSRF protection for OmniAuth 2: `omniauth-rails_csrf_protection`

## 1) Gems
Add to Gemfile and bundle:

```ruby
# OmniAuth core + CSRF protection for OmniAuth 2
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection'

# Providers
gem 'omniauth-google-oauth2', '~> 1.1'
gem 'omniauth-apple', '~> 1.2'
```

## 2) Devise Initializer
Configure providers in `config/initializers/devise.rb`:

```ruby
# Enable OmniAuth strategies
config.omniauth :google_oauth2,
  ENV['GOOGLE_CLIENT_ID'],
  ENV['GOOGLE_CLIENT_SECRET'],
  scope: 'email,profile'

config.omniauth :apple,
  ENV['APPLE_CLIENT_ID'],
  '',
  scope: 'email name',
  team_id: ENV['APPLE_TEAM_ID'],
  key_id: ENV['APPLE_KEY_ID'],
  pem: ENV['APPLE_P8_KEY']
```

Notes:
- OmniAuth 2 uses POST by default; ensure links are rendered as forms (see UI section).
- Apple requires the private key content in `APPLE_P8_KEY` (PEM contents), or load from a file and pass as `pem: File.read(...)`.

## 3) User Model
Make users OmniAuth-able in `app/models/user.rb`:

```ruby
# Add omniauthable and providers
:omniauthable, omniauth_providers: %i[google_oauth2 apple]
```

Add finder/creator:

```ruby
def self.from_omniauth(auth)
  # Find by provider/uid
  user = find_by(provider: auth.provider, uid: auth.uid)

  # Optionally link existing account by email
  user ||= find_by(email: auth.info.email)&.tap do |u|
    u.update(provider: auth.provider, uid: auth.uid) if u && u.provider.blank?
  end

  # Create new if none exist
  user ||= create!(
    name:  auth.info.name.presence || auth.info.first_name || auth.info.email,
    email: auth.info.email,
    password: Devise.friendly_token[0, 32],
    provider: auth.provider,
    uid: auth.uid
  )

  user
end
```

## 4) DB Migration
Add provider/uid columns and index:

```ruby
class AddOmniauthToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_index  :users, [:provider, :uid], unique: true
  end
end
```

## 5) Routes
Use Devise callbacks controller in `config/routes.rb`:

```ruby
devise_for :users, controllers: {
  omniauth_callbacks: 'users/omniauth_callbacks'
}
```

## 6) Callbacks Controller
Create `app/controllers/users/omniauth_callbacks_controller.rb`:

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth('Google')
  end

  def apple
    handle_auth('Apple')
  end

  private

  def handle_auth(kind)
    auth = request.env['omniauth.auth']
    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      redirect_to new_user_session_path, alert: 'Authentication failed.'
    end
  end
end
```

## 7) Sign-In Page Buttons
In `app/views/devise/sessions/new.html.erb`, add provider buttons. OmniAuth 2 prefers POST, so use `button_to` or a form:

```erb
<div class="social-signin">
  <%= button_to 'Sign in with Google', user_google_oauth2_omniauth_authorize_path, method: :post, class: 'btn btn-outline-dark w-100 mb-2', data: { testid: 'signin-google-btn' } %>
  <%= button_to 'Sign in with Apple', user_apple_omniauth_authorize_path, method: :post, class: 'btn btn-outline-dark w-100', data: { testid: 'signin-apple-btn' } %>
</div>
```

## 8) Credentials and ENV
Store secrets via Rails credentials or environment variables.

Required env vars:
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `APPLE_CLIENT_ID` (Services ID)
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_P8_KEY` (PEM contents of the .p8 private key)

Example to set with Rails credentials:

```bash
bin/rails credentials:edit
# Add under appropriate env:
# google:
#   client_id: ...
#   client_secret: ...
# apple:
#   client_id: ...
#   team_id: ...
#   key_id: ...
#   p8_key: |-
#     -----BEGIN PRIVATE KEY-----
#     ...
#     -----END PRIVATE KEY-----
```

Then read them into ENV in your deploy platform or use `Rails.application.credentials` directly in Devise config instead of `ENV[...]`.

## 9) Provider Console Setup
- Google Cloud Console
  - Create OAuth 2.0 Client ID (Web application)
  - Authorized redirect URI: `https://YOUR-DOMAIN/users/auth/google_oauth2/callback`
- Apple Developer
  - Create Services ID (identifier equals `APPLE_CLIENT_ID`)
  - Create Sign in with Apple key (.p8), note Key ID and Team ID
  - Configure Return URL: `https://YOUR-DOMAIN/users/auth/apple/callback`
  - Configure Web Domain association (requires HTTPS)

## 10) Security Notes
- OmniAuth 2 requires POST for request phase; do not use GET links.
- Ensure app is served over HTTPS in production (Apple requires it).
- Consider account linking UX when an email exists from password auth.
- Validate email presence from Apple—Apple may hide email unless “share my email” is chosen. Use `auth.info.email` fallback handling.

## 11) Testing Checklist
- Dev: set env vars and use `HOST` with HTTPS in `development.rb` for callbacks.
- Verify Google flow end-to-end, including returning users.
- Verify Apple flow, including private relay emails.
- Check that existing password users can link social on first social sign-in (via email match) and sign in thereafter.
- System tests: click `[data-testid='signin-google-btn']`/`signin-apple-btn` and mock OmniAuth.

Mocking OmniAuth in test:

```ruby
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
  provider: 'google_oauth2', uid: '12345',
  info: { email: 'demo@example.com', name: 'Demo User' }
)
```

## 12) Troubleshooting
- `OmniAuth::AuthenticityError`: ensure `omniauth-rails_csrf_protection` is installed and buttons use POST.
- Callback 404: verify routes and provider redirect URIs match exactly.
- Apple invalid_client: check Team ID, Key ID, Client ID, and PEM contents.
- Email is nil for Apple: handle with generated placeholder or prompt to add email.
