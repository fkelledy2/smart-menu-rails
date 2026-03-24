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

  # Square payments — disabled by default; enable per-restaurant via Flipper UI.
  unless Flipper.exist?(:square_payments)
    Flipper.add(:square_payments)
  end

  # QR Security v1 — dining session enforcement. Enabled globally from day one.
  # The backfill migration ensures all existing smartmenus have public_tokens.
  unless Flipper.exist?(:qr_security_v1)
    Flipper.enable(:qr_security_v1)
  end

  # Payment gating — per-restaurant flag to enforce pre-payment ordering.
  # Disabled by default; enable per-restaurant via Flipper UI.
  unless Flipper.exist?(:payment_gating)
    Flipper.add(:payment_gating)
  end
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
  # DB may be unreachable (CI asset precompile), or tables may not exist yet (db:create / db:migrate)
  Rails.logger.warn "[Flipper] Skipping feature flag seeding: #{e.message}"
end
