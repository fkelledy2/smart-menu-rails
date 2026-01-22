class Payments::WebhooksController < ApplicationController
  require 'stripe'

  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    evt = build_stripe_event(payload, sig_header)
    return head :bad_request unless evt

    case evt.type
    when 'payment_intent.succeeded'
      handle_payment_intent_succeeded(evt)
    else
      # Ignore other events in v1
    end

    head :ok
  end

  private

  def build_stripe_event(payload, sig_header)
    secret = begin
      Rails.application.credentials.dig(:stripe, :webhook_secret) ||
        Rails.application.credentials.dig(:stripe_webhook_secret)
    rescue StandardError
      nil
    end
    secret = ENV['STRIPE_WEBHOOK_SECRET'] if secret.blank?

    if secret.present?
      Stripe::Webhook.construct_event(payload, sig_header, secret)
    else
      # No signature verification configured; accept but log.
      Rails.logger.warn('[StripeWebhook] STRIPE_WEBHOOK_SECRET not configured; skipping signature verification')
      Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
    end
  rescue StandardError => e
    Rails.logger.warn("[StripeWebhook] Invalid payload/signature: #{e.class}: #{e.message}")
    nil
  end

  def handle_payment_intent_succeeded(evt)
    obj = evt.data.object
    order_id = begin
      md = obj.metadata
      md && (md['order_id'] || md[:order_id] || (md.respond_to?(:order_id) ? md.order_id : nil))
    rescue StandardError
      nil
    end
    return if order_id.blank?

    ordr = Ordr.find_by(id: order_id)
    return unless ordr

    pi_id = obj.id.to_s

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'paid',
      entity_type: 'payment',
      entity_id: ordr.id,
      source: 'webhook',
      idempotency_key: "stripe:payment_intent:#{pi_id}",
      payload: {
        provider: 'stripe',
        external_ref: pi_id,
      },
    )

    OrderEventProjector.project!(ordr.id)

    broadcast_state(ordr)
  rescue StandardError => e
    Rails.logger.error("[StripeWebhook] Failed to process payment_intent.succeeded: #{e.class}: #{e.message}")
  end

  def broadcast_state(ordr)
    menu = ordr.menu
    restaurant = ordr.restaurant
    tablesetting = ordr.tablesetting

    payload = SmartmenuState.for_context(
      menu: menu,
      restaurant: restaurant,
      tablesetting: tablesetting,
      open_order: ordr,
      ordrparticipant: nil,
      menuparticipant: nil,
      session_id: 'webhook',
    )

    ActionCable.server.broadcast("ordr_#{ordr.id}_channel", { state: payload })

    begin
      smartmenu = Smartmenu.find_by(menu_id: menu.id, tablesetting_id: tablesetting.id)
      if smartmenu&.slug.present?
        ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", { state: payload })
      end
    rescue StandardError
      nil
    end
  end
end
