# frozen_string_literal: true

require 'flipper'
require 'flipper/adapters/active_record'

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end

# Register known feature flags and their defaults.
# Runs after_initialize so the database connection is ready.
Rails.application.config.after_initialize do
  # Homepage testimonials — enabled by default to preserve current behaviour.
  # Once the flag exists, admins manage it via /flipper UI.
  unless Flipper.exist?(:homepage_testimonials)
    Flipper.enable(:homepage_testimonials)
  end
rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
  # Tables may not exist yet (e.g. during db:create / db:migrate)
  Rails.logger.warn "[Flipper] Skipping feature flag seeding: #{e.message}"
end
