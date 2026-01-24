class Payments::WebhooksController < ApplicationController
  require 'stripe'

  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    evt = build_stripe_event(payload, sig_header)
    return head :bad_request unless evt

    Rails.logger.warn("[StripeWebhook] Received event type=#{evt.type} id=#{evt.id} livemode=#{evt.livemode}")

    case evt.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(evt)
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
      md && (
        md['order_id'] || md[:order_id] ||
        md['orderId'] || md[:orderId] ||
        (md.respond_to?(:order_id) ? md.order_id : nil)
      )
    rescue StandardError
      nil
    end
    if order_id.blank?
      Rails.logger.warn("[StripeWebhook] payment_intent.succeeded missing order_id (event_id=#{evt.id})")
      return
    end

    ordr = Ordr.find_by(id: order_id)
    unless ordr
      Rails.logger.warn("[StripeWebhook] payment_intent.succeeded order not found (order_id=#{order_id} event_id=#{evt.id})")
      return
    end

    split_payment_id = begin
      md = obj.metadata
      md && (md['ordr_split_payment_id'] || md[:ordr_split_payment_id])
    rescue StandardError
      nil
    end

    pi_id = obj.id.to_s

    if split_payment_id.present?
      mark_split_payment_succeeded(ordr: ordr, split_payment_id: split_payment_id, checkout_session_id: nil, payment_intent_id: pi_id)
      emit_paid_if_settled!(ordr: ordr, idempotency_key: "stripe:split_paid:#{ordr.id}", external_ref: pi_id)
      emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:split_closed:#{ordr.id}", external_ref: pi_id)
      Rails.logger.warn("[StripeWebhook] split payment settled -> paid/closed (ordr_id=#{ordr.id} event_id=#{evt.id})")
      broadcast_state(ordr.reload)
      return
    end

    return if OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?

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

    Rails.logger.warn("[StripeWebhook] payment_intent.succeeded -> paid (ordr_id=#{ordr.id} event_id=#{evt.id})")
    broadcast_state(ordr)
  rescue StandardError => e
    Rails.logger.error("[StripeWebhook] Failed to process payment_intent.succeeded: #{e.class}: #{e.message}")
  end

  def handle_checkout_session_completed(evt)
    obj = evt.data.object

    md = begin
      obj.metadata
    rescue StandardError
      nil
    end

    order_id = begin
      md && (
        md['order_id'] || md[:order_id] ||
        md['orderId'] || md[:orderId]
      )
    rescue StandardError
      nil
    end

    if order_id.blank?
      order_id = begin
        obj.client_reference_id
      rescue StandardError
        nil
      end
    end

    if order_id.blank?
      Rails.logger.warn("[StripeWebhook] checkout.session.completed missing order_id/client_reference_id (event_id=#{evt.id})")
      return
    end

    ordr = Ordr.find_by(id: order_id)
    unless ordr
      Rails.logger.warn("[StripeWebhook] checkout.session.completed order not found (order_id=#{order_id} event_id=#{evt.id})")
      return
    end

    checkout_id = obj.id.to_s
    pi_id = begin
      obj.payment_intent.to_s
    rescue StandardError
      nil
    end

    split_payment_id = begin
      md && (md['ordr_split_payment_id'] || md[:ordr_split_payment_id])
    rescue StandardError
      nil
    end

    if split_payment_id.present?
      mark_split_payment_succeeded(ordr: ordr, split_payment_id: split_payment_id, checkout_session_id: checkout_id, payment_intent_id: pi_id)
      emit_paid_if_settled!(ordr: ordr, idempotency_key: "stripe:split_paid:#{ordr.id}", external_ref: checkout_id)
      emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:split_closed:#{ordr.id}", external_ref: checkout_id)
      Rails.logger.warn("[StripeWebhook] checkout.session.completed (split) -> paid/closed (ordr_id=#{ordr.id} event_id=#{evt.id})")
    else
      return if OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?
      emit_paid!(ordr: ordr, idempotency_key: "stripe:checkout_session:#{checkout_id}", external_ref: checkout_id)
      emit_closed_if_paid!(ordr: ordr, idempotency_key: "stripe:checkout_session_closed:#{checkout_id}", external_ref: checkout_id)
      Rails.logger.warn("[StripeWebhook] checkout.session.completed -> paid/closed (ordr_id=#{ordr.id} event_id=#{evt.id})")
    end

    OrderEventProjector.project!(ordr.id)
    broadcast_state(ordr.reload)
  rescue StandardError => e
    Rails.logger.error("[StripeWebhook] Failed to process checkout.session.completed: #{e.class}: #{e.message}")
  end

  def mark_split_payment_succeeded(ordr:, split_payment_id:, checkout_session_id:, payment_intent_id:)
    sp = ordr.ordr_split_payments.find_by(id: split_payment_id)
    return unless sp

    updates = {
      status: OrdrSplitPayment.statuses['succeeded'],
    }
    updates[:stripe_checkout_session_id] = checkout_session_id if checkout_session_id.present?
    updates[:stripe_payment_intent_id] = payment_intent_id if payment_intent_id.present?

    sp.update!(updates)
  rescue StandardError => e
    Rails.logger.error("[StripeWebhook] Failed to update split payment: #{e.class}: #{e.message}")
  end

  def emit_paid_if_settled!(ordr:, idempotency_key:, external_ref:)
    return if OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?

    has_splits = ordr.ordr_split_payments.exists?
    return emit_paid!(ordr: ordr, idempotency_key: idempotency_key, external_ref: external_ref) unless has_splits

    unsettled = ordr.ordr_split_payments.where.not(status: OrdrSplitPayment.statuses['succeeded']).exists?
    return if unsettled

    emit_paid!(ordr: ordr, idempotency_key: idempotency_key, external_ref: external_ref)
  end

  def emit_paid!(ordr:, idempotency_key:, external_ref:)
    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'paid',
      entity_type: 'payment',
      entity_id: ordr.id,
      source: 'webhook',
      idempotency_key: idempotency_key,
      payload: {
        provider: 'stripe',
        external_ref: external_ref.to_s,
      },
    )
  end

  def emit_closed_if_paid!(ordr:, idempotency_key:, external_ref:)
    return if OrderEvent.where(ordr_id: ordr.id, event_type: 'closed').exists?

    paid = OrderEvent.where(ordr_id: ordr.id, event_type: 'paid').exists?
    return unless paid

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'closed',
      entity_type: 'order',
      entity_id: ordr.id,
      source: 'webhook',
      idempotency_key: idempotency_key,
      payload: {
        provider: 'stripe',
        external_ref: external_ref.to_s,
      },
    )
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
