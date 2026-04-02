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

  # Partner Integrations — event-driven API layer for workforce/CRM partners.
  # Disabled by default; enable per-restaurant once a partner has been configured.
  unless Flipper.exist?(:partner_integrations)
    Flipper.add(:partner_integrations)
  end

  # Menu Experiments — A/B testing for menu versions (Pro+ plan only).
  # Disabled by default; enable per-restaurant via Flipper UI once the restaurant
  # has at least two menu versions and is on a Pro or Business plan.
  unless Flipper.exist?(:menu_experiments)
    Flipper.add(:menu_experiments)
  end

  # Wait Time Estimation — per-restaurant opt-in for the walk-in queue dashboard.
  # Disabled by default; enable per-restaurant via Flipper UI.
  unless Flipper.exist?(:wait_time_estimation)
    Flipper.add(:wait_time_estimation)
  end

  # Wait Time SMS — stretch goal; enables SMS notification when table is ready.
  # Disabled by default. Requires Twilio credentials before enabling.
  unless Flipper.exist?(:wait_time_sms)
    Flipper.add(:wait_time_sms)
  end

  # Heroku Cost Inventory (#16) — enables live Heroku API calls in SpaceInventoryService.
  # Disabled by default. Requires HEROKU_PLATFORM_API_TOKEN to be set before enabling.
  # In mock mode (flag off), jobs persist stub data for development/testing.
  unless Flipper.exist?(:heroku_cost_inventory)
    Flipper.add(:heroku_cost_inventory)
  end

  # Cost Insights Admin (#15) — enables the admin cost dashboard and vendor cost screens.
  # Disabled by default; enable for super_admin users once the first cost data is entered.
  unless Flipper.exist?(:cost_insights_admin)
    Flipper.add(:cost_insights_admin)
  end

  # Cost-Indexed Pricing (#14) — enables new signup flow to use current PricingModel.
  # Disabled by default until the first pricing model is published.
  unless Flipper.exist?(:cost_indexed_pricing)
    Flipper.add(:cost_indexed_pricing)
  end

  # Employee Role Promotion (#29) — enables the "Change Role" UI in the staff management section.
  # Disabled by default; enable per-restaurant or globally via Flipper UI.
  # When disabled, existing roles are unaffected — only the UI action is hidden.
  unless Flipper.exist?(:employee_role_promotion)
    Flipper.add(:employee_role_promotion)
  end

  # Realtime Ordritem Tracking (#34) — gates item-level fulfillment status UI for customers,
  # batch action buttons on kitchen/bar dashboards, and OrdritemEvent creation.
  # Migrations run unconditionally; this flag controls activation per restaurant during beta.
  unless Flipper.exist?(:ordritem_realtime_tracking)
    Flipper.add(:ordritem_realtime_tracking)
  end

  # Agent Framework (#17) — master switch for all AI agent workflows.
  # Must be enabled per-restaurant before any agent workflow runs.
  # Disabled by default; enable only after reviewing AgentPolicy defaults for the restaurant.
  unless Flipper.exist?(:agent_framework)
    Flipper.add(:agent_framework)
  end

  # Menu Import Agent (#18) — per-restaurant flag for the AI-powered menu import workflow.
  # Requires agent_framework to also be enabled. Disabled by default.
  unless Flipper.exist?(:agent_menu_import)
    Flipper.add(:agent_menu_import)
  end
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
  # DB may be unreachable (CI asset precompile), or tables may not exist yet (db:create / db:migrate)
  Rails.logger.warn "[Flipper] Skipping feature flag seeding: #{e.message}"
end
