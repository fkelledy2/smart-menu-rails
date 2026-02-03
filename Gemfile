source 'https://rubygems.org'

ruby '3.3.10'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.2.2', '>= 7.2.2.2'

# Use Rack 3.x for security improvements
gem 'rack', '~> 3.0'

# Pin minitest to 5.x for compatibility (6.x has breaking changes)
gem 'minitest', '~> 5.25'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Connection pooling
gem 'connection_pool'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 7.0.3'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

gem 'google-cloud-vision', '~> 2.0.2'

# Error tracking and monitoring
gem 'sentry-rails', '~> 5.12'
gem 'sentry-ruby', '~> 5.12'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.18', require: false
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'factory_bot_rails', '~> 6.4'
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 6.1'
  gem 'rswag-api'
  gem 'rswag-ui'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'letter_opener'
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'rswag-specs'
  gem 'selenium-webdriver'
end
gem 'aasm'
gem 'active_model_serializers'
gem 'allow_numeric'
gem 'analytics-ruby', '~> 2.4.0', require: 'segment/analytics'
gem 'aws-sdk-s3', require: false
gem 'bullet', group: %i[development test]
gem 'cityhash'
gem 'country_select', '~> 8.0'
gem 'cropper_rails'
gem 'cssbundling-rails'
gem 'currencies'
gem 'currency_select'
gem 'deepl-rb', require: 'deepl'
gem 'devise', '~> 4.9'
gem 'dotenv-rails'
gem 'fastimage'
gem 'friendly_id', '~> 5.4'
gem 'gmaps-autocomplete-rails'
gem 'http_accept_language'
gem 'httparty'
gem 'identity_cache'
gem 'image_processing', '~> 1.12', '>= 1.12.1'
gem 'pgvector', '= 0.3.2'
gem 'jquery-rails'
gem 'jsbundling-rails'
gem 'madmin'
gem 'mini_magick'
gem 'name_of_person', '~> 1.1'
gem 'nokogiri'
gem 'noticed', '~> 2.0'
gem 'omniauth'
gem 'omniauth-facebook', '~> 8.0'
gem 'omniauth-github', '~> 2.0'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-google-oauth2', '~> 1.1'
gem 'omniauth-apple', '~> 1.2'
gem 'omniauth-spotify'
gem 'omniauth-twitter', '~> 1.4'
gem 'openai', '~> 0.25.0'
gem 'pay', '~> 8.0'
gem 'pdf-reader'
gem 'pretender', '~> 0.3.4'
gem 'pundit', '~> 2.1'
gem 'rack-cors'
gem 'receipts', '~> 2.0'
gem 'redis-activesupport' # Required to hook into Rails cache store
gem 'redis-store'
gem 'requestjs-rails'
gem 'responders', github: 'heartcombo/responders', branch: 'main'
gem 'rqrcode', '~> 2.2'
gem 'rqrcode-rails3'
gem 'rspotify'
gem 'ruby-limiter'
gem 'ruby-openai'
gem 'seed_dump'
gem 'shrine', '~> 3.3'
gem 'sidekiq', '~> 7.0'
gem 'simplecov', require: false, group: :test
gem 'sitemap_generator', '~> 6.1'
gem 'squasher'
gem 'stackprof'
gem 'stripe', '~> 13.0'
gem 'tabulator-rails'
gem 'tom-select-rails', '~> 2.3'
gem 'whenever', require: false

# Memcached client for Rails cache store (used with MemCachier) for IdentityCache CAS support
gem 'dalli', '~> 3.2'

group :development, :test do
  gem 'i18n-tasks', '~> 1.0'

  # CI/CD and Code Quality Tools
  gem 'brakeman', '~> 6.0', require: false
  gem 'bundler-audit', '~> 0.9', require: false
  gem 'rubocop', '~> 1.57', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', '~> 1.19', require: false
  gem 'rubocop-rails', '~> 2.22', require: false
  gem 'rubocop-rspec', '~> 2.25', require: false
  gem 'rubocop-rspec_rails', require: false
end

gem "erb_lint", "~> 0.9.0", groups: [:development, :test]
