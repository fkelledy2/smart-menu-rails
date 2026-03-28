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

  # Receipt email — enables email receipt delivery for staff and customers.
  # Disabled by default; enable per-restaurant or globally via Flipper UI.
  unless Flipper.exist?(:receipt_email)
    Flipper.add(:receipt_email)
  end

  # Receipt SMS — stretch goal; enables SMS delivery path via Twilio.
  # Disabled by default. Requires TWILIO_* env vars before enabling.
  unless Flipper.exist?(:receipt_sms)
    Flipper.add(:receipt_sms)
  end

  # JWT API access — enables admin-issued JWT tokens for the REST API.
  # Disabled by default; enable globally or per-restaurant via Flipper UI
  # once the admin has issued at least one token and tested it.
  unless Flipper.exist?(:jwt_api_access)
    Flipper.add(:jwt_api_access)
  end

  # CRM Sales Funnel — internal sales pipeline tool.
  # Disabled by default; enable for @mellow.menu admin users via Flipper UI.
  unless Flipper.exist?(:crm_sales_funnel)
    Flipper.add(:crm_sales_funnel)
  end

  # Smartmenu Theming — per-smartmenu visual theme (Modern / Rustic / Elegant).
  # Enabled by default; disable via Flipper UI to hide the selector during rollback.
  unless Flipper.exist?(:smartmenu_theming)
    Flipper.enable(:smartmenu_theming)
  end
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
  # DB may be unreachable (CI asset precompile), or tables may not exist yet (db:create / db:migrate)
  Rails.logger.warn "[Flipper] Skipping feature flag seeding: #{e.message}"
end
