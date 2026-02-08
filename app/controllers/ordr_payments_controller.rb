class OrdrPaymentsController < ApplicationController
  require 'stripe'
  require 'digest'

  skip_before_action :verify_authenticity_token,
                     only: %i[request_bill split_evenly checkout_session]

  before_action :set_restaurant
  before_action :set_ordr

  after_action :verify_authorized

  def request_bill
    authorize @ordr, :update?

    if %w[billrequested paid closed].include?(@ordr.status.to_s)
      render json: { ok: true, status: @ordr.status.to_s }, status: :ok
      return
    end

    begin
      OrdrStationTicketService.submit_unsubmitted_items!(@ordr)
      @ordr.reload
    rescue StandardError
      begin
        opened_status = Ordritem.statuses['opened']
        ordered_status = Ordritem.statuses['ordered']

        @ordr.ordritems.where(status: opened_status).update_all(status: ordered_status)
        @ordr.update(status: 'ordered') if @ordr.status.to_s == 'opened'
        @ordr.reload
      rescue StandardError
        nil
      end
    end

    if @ordr.ordritems.exists?(status: Ordritem.statuses['opened'])
      render json: { ok: false, error: 'Cannot request bill while items are still open' }, status: :unprocessable_content
      return
    end

    submitted_statuses = %w[ordered preparing ready delivered]
    unless @ordr.ordritems.exists?(status: submitted_statuses.map { |s| Ordritem.statuses[s] })
      render json: { ok: false, error: 'Cannot request bill with no submitted items' }, status: :unprocessable_content
      return
    end

    evt = OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'bill_requested',
      entity_type: 'order',
      entity_id: @ordr.id,
      source: current_user ? 'staff' : 'guest',
      idempotency_key: "bill_requested:#{@ordr.id}",
      payload: {
        reason: 'request_bill',
      },
    )

    OrderEventProjector.project!(@ordr.id)
    @ordr.reload

    broadcast_state(@ordr)

    render json: { ok: true, status: @ordr.status.to_s, event_id: evt.id }, status: :ok
  end

  def split_evenly
    authorize @ordr, :update?

    if @ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to split' }, status: :unprocessable_content
      return
    end

    participants = customer_participants(@ordr)
    n = participants.length

    if n < 2
      render json: { ok: false, error: 'Need at least 2 participants to split evenly' }, status: :unprocessable_content
      return
    end

    currency = @ordr.restaurant.currency.presence || 'USD'
    total_cents = total_amount_cents(@ordr)

    if total_cents <= 0
      render json: { ok: false, error: 'Order total is zero' }, status: :unprocessable_content
      return
    end

    shares = compute_even_split(total_cents, n)

    @ordr.ordr_split_payments.delete_all

    created = []
    participants.each_with_index do |p, idx|
      sp = @ordr.ordr_split_payments.create!(
        ordrparticipant: p,
        amount_cents: shares[idx],
        currency: currency,
        status: :requires_payment,
      )
      created << sp
    end

    render json: {
      ok: true,
      order_id: @ordr.id,
      total_cents: total_cents,
      currency: currency,
      split_payments: created.map do |sp|
        {
          id: sp.id,
          ordrparticipant_id: sp.ordrparticipant_id,
          amount_cents: sp.amount_cents,
          status: sp.status,
        }
      end,
    }, status: :ok
  end

  def checkout_session
    authorize @ordr, :update?

    if @ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to pay' }, status: :unprocessable_content
      return
    end

    if Stripe.api_key.blank?
      key = begin
        Rails.application.credentials.stripe_secret_key
      rescue StandardError
        nil
      end
      if key.blank?
        key = begin
          Rails.application.credentials.dig(:stripe, :secret_key) ||
            Rails.application.credentials.dig(:stripe, :api_key)
        rescue StandardError
          nil
        end
      end
      key = ENV.fetch('STRIPE_SECRET_KEY', nil) if key.blank?

      if key.present?
        Stripe.api_key = key
      else
        Rails.logger.warn('[StripeCheckout] Stripe.api_key blank and no STRIPE_SECRET_KEY / credentials key found')
        render json: { ok: false, error: 'Stripe is not configured' }, status: :service_unavailable
        return
      end
    end

    currency = @ordr.restaurant.currency.presence || 'USD'

    split_payment = nil
    if params[:ordr_split_payment_id].present?
      split_payment = @ordr.ordr_split_payments.find_by(id: params[:ordr_split_payment_id])
      unless split_payment
        render json: { ok: false, error: 'Split payment not found' }, status: :not_found
        return
      end
    end

    requested_amount_cents = params[:amount_cents].to_i
    amount_cents = if requested_amount_cents.positive?
                     requested_amount_cents
                   else
                     split_payment ? split_payment.amount_cents.to_i : total_amount_cents(@ordr)
                   end
    if amount_cents <= 0
      render json: { ok: false, error: 'Order total is zero' }, status: :unprocessable_content
      return
    end

    success_url = params[:success_url].presence || root_url
    cancel_url = params[:cancel_url].presence || root_url

    metadata = {
      order_id: @ordr.id,
      restaurant_id: @ordr.restaurant_id,
    }
    metadata[:ordr_split_payment_id] = split_payment.id if split_payment

    session = Stripe::Checkout::Session.create(
      mode: 'payment',
      success_url: success_url,
      cancel_url: cancel_url,
      client_reference_id: @ordr.id.to_s,
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: currency.to_s.downcase,
            unit_amount: amount_cents,
            product_data: {
              name: "#{@ordr.restaurant.name} Order #{@ordr.id}",
            },
          },
        },
      ],
      metadata: metadata,
      payment_intent_data: {
        metadata: metadata,
      },
    )

    key_fingerprint = Digest::SHA256.hexdigest(Stripe.api_key.to_s)[0, 12]
    Rails.logger.warn(
      "[StripeCheckout] Created session (ordr_id=#{@ordr.id} split_payment_id=#{split_payment&.id} session_id=#{session.id} payment_intent_id=#{session.payment_intent.presence} stripe_key_fp=#{key_fingerprint})",
    )

    split_payment&.update!(
      status: :pending,
      stripe_checkout_session_id: session.id.to_s,
      stripe_payment_intent_id: session.payment_intent.to_s.presence,
    )

    render json: { ok: true, checkout_session_id: session.id.to_s, checkout_url: session.url.to_s }, status: :ok
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  def set_ordr
    @ordr = Ordr.find(params[:id])

    return unless @restaurant && @ordr.restaurant_id != @restaurant.id

    skip_authorization
    render json: { ok: false, error: 'Order not found for restaurant' }, status: :not_found
    nil
  end

  def customer_participants(ordr)
    # One participant per sessionid
    p = ordr.ordrparticipants.where(role: Ordrparticipant.roles['customer'])
    p = p.order(:id).to_a
    seen = {}
    p.select do |x|
      sid = x.sessionid.to_s
      next false if sid.blank? || seen[sid]

      seen[sid] = true
    end
  end

  def total_amount_cents(ordr)
    cents = ((ordr.gross.to_f - ordr.tip.to_f) * 100.0).round
    return cents if cents.positive?

    # Fallback to ordritems total
    (ordr.ordritems.sum(:ordritemprice).to_f * 100.0).round
  end

  def compute_even_split(total_cents, n)
    base = total_cents / n
    remainder = total_cents % n
    (0...n).map { |i| base + (i < remainder ? 1 : 0) }
  end

  def broadcast_state(ordr)
    menu = ordr.menu
    restaurant = ordr.restaurant
    tablesetting = ordr.tablesetting

    participant = begin
      ordr.ordrparticipants.find_by(sessionid: session.id.to_s)
    rescue StandardError
      nil
    end

    payload = SmartmenuState.for_context(
      menu: menu,
      restaurant: restaurant,
      tablesetting: tablesetting,
      open_order: ordr,
      ordrparticipant: participant,
      menuparticipant: nil,
      session_id: session.id.to_s,
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
