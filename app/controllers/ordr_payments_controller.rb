class OrdrPaymentsController < ApplicationController
  include CsrfSafeGuestActions

  require 'stripe'
  require 'digest'

  skip_before_action :verify_authenticity_token,
                     only: %i[request_bill split_evenly split_plan checkout_session create_inline_payment
                              cash_payment checkout_qr]

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
    rescue StandardError => e
      Rails.logger.warn("[OrdrPaymentsController#request_bill] submit_unsubmitted_items failed for order=#{@ordr.id}: #{e.message}")
      begin
        opened_status = Ordritem.statuses['opened']
        ordered_status = Ordritem.statuses['ordered']

        @ordr.ordritems.where(status: opened_status).update_all(status: ordered_status)
        @ordr.update(status: 'ordered') if @ordr.status.to_s == 'opened'
        @ordr.reload
      rescue StandardError => e
        Rails.logger.warn("[OrdrPaymentsController#request_bill] fallback item status update failed for order=#{@ordr.id}: #{e.message}")
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
    return unless authorize_split_access!

    if @ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to split' }, status: :unprocessable_content
      return
    end

    participants = customer_participants(@ordr)
    if participants.length < 2
      render json: { ok: false, error: 'Need at least 2 participants to split evenly' }, status: :unprocessable_content
      return
    end

    result = Payments::SplitPlanUpsertService.new(
      ordr: @ordr,
      actor: current_user,
      split_method: :equal,
      participant_ids: participants.map(&:id),
    ).call

    unless result.success?
      render json: { ok: false, error: result.errors.to_sentence }, status: :unprocessable_content
      return
    end

    render json: {
      ok: true,
      order_id: @ordr.id,
      total_cents: result.plan.total_allocated_cents,
      currency: @ordr.restaurant.currency.presence || 'USD',
      split_payments: result.plan.ordr_split_payments.order(:position).map do |sp|
        {
          id: sp.id,
          ordrparticipant_id: sp.ordrparticipant_id,
          amount_cents: sp.amount_cents,
          status: sp.status,
        }
      end,
    }, status: :ok
  end

  def split_plan
    return unless authorize_split_access!

    if request.get? || request.head?
      plan = @ordr.ordr_split_plan
      render json: { ok: true, order_id: @ordr.id, split_plan: plan ? split_plan_payload(plan)[:split_plan] : nil }, status: :ok
      return
    end

    result = Payments::SplitPlanUpsertService.new(
      ordr: @ordr,
      actor: current_user,
      split_method: params[:split_method],
      participant_ids: Array(params[:participant_ids]),
      custom_amounts_cents: params[:custom_amounts_cents] || {},
      percentage_basis_points: params[:percentage_basis_points] || {},
      item_assignments: params[:item_assignments] || {},
    ).call

    unless result.success?
      render json: { ok: false, error: result.errors.to_sentence }, status: :unprocessable_content
      return
    end

    render json: split_plan_payload(result.plan), status: :ok
  end

  def checkout_session
    return unless authorize_split_access!

    if @ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to pay' }, status: :unprocessable_content
      return
    end

    currency = @ordr.restaurant.currency.presence || 'USD'

    split_payment = nil
    if params[:ordr_split_payment_id].present?
      split_payment = @ordr.ordr_split_payments.find_by(id: params[:ordr_split_payment_id])
      unless split_payment
        render json: { ok: false, error: 'Split payment not found' }, status: :not_found
        return
      end

      if split_payment.ordrparticipant_id.present? && current_user.blank? && split_payment.ordrparticipant&.sessionid.to_s != safe_session_id
        render json: { ok: false, error: 'You can only pay your own assigned share' }, status: :forbidden
        return
      end

      unless split_payment.pay_ready? || split_payment.pending?
        render json: { ok: false, error: 'Split payment is not payable' }, status: :unprocessable_content
        return
      end

      split_payment.ordr_split_plan&.freeze! if split_payment.ordr_split_plan && !split_payment.ordr_split_plan.split_frozen?
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

    if @ordr.restaurant.square_provider?
      create_square_checkout(split_payment: split_payment, amount_cents: amount_cents, currency: currency,
                             success_url: success_url, cancel_url: cancel_url,)
    else
      create_stripe_checkout(split_payment: split_payment, amount_cents: amount_cents, currency: currency,
                             success_url: success_url, cancel_url: cancel_url,)
    end
  end

  def cash_payment
    unless current_user || @current_employee
      skip_authorization
      render json: { ok: false, error: 'Staff authentication required' }, status: :forbidden
      return
    end

    authorize @ordr, :update?

    unless %w[billrequested].include?(@ordr.status.to_s)
      render json: { ok: false, error: 'Order must be in billrequested status to mark as cash paid' },
             status: :unprocessable_content
      return
    end

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'paid',
      entity_type: 'order',
      entity_id: @ordr.id,
      source: 'staff',
      idempotency_key: "cash_paid:#{@ordr.id}",
      payload: { method: 'cash', recorded_by: current_user&.id || current_employee&.id },
    )

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'closed',
      entity_type: 'order',
      entity_id: @ordr.id,
      source: 'staff',
      idempotency_key: "cash_closed:#{@ordr.id}",
      payload: { method: 'cash' },
    )

    OrderEventProjector.project!(@ordr.id)
    @ordr.reload
    broadcast_state(@ordr)

    render json: { ok: true, status: @ordr.status.to_s }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[CashPayment] Failed for ordr=#{@ordr.id}: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'Failed to record cash payment' }, status: :service_unavailable
  end

  def checkout_qr
    unless current_user || @current_employee
      skip_authorization
      render json: { ok: false, error: 'Staff authentication required' }, status: :forbidden
      return
    end

    authorize @ordr, :update?

    unless @ordr.status.to_s == 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to generate payment QR' },
             status: :unprocessable_content
      return
    end

    currency = @ordr.restaurant.currency.presence || 'USD'
    amount_cents = total_amount_cents(@ordr)

    if amount_cents <= 0
      render json: { ok: false, error: 'Order total is zero' }, status: :unprocessable_content
      return
    end

    success_url = params[:success_url].presence || root_url
    cancel_url  = params[:cancel_url].presence  || root_url

    checkout_url = if @ordr.restaurant.square_provider?
                     result = Payments::Providers::SquareAdapter.new(restaurant: @ordr.restaurant)
                       .create_checkout_session!(
                         payment_attempt: PaymentAttempt.create!(
                           ordr: @ordr, restaurant: @ordr.restaurant,
                           provider: :square, amount_cents: amount_cents,
                           currency: currency, status: :requires_action,
                           charge_pattern: :direct, merchant_model: :restaurant_mor,
                           idempotency_key: SecureRandom.uuid,
                         ),
                         ordr: @ordr, amount_cents: amount_cents,
                         currency: currency, success_url: success_url, cancel_url: cancel_url,
                       )
                     result[:checkout_url]
                   else
                     stripe_key = Stripe.api_key.presence ||
                                  Rails.application.credentials.dig(:stripe, :secret_key) ||
                                  ENV.fetch('STRIPE_SECRET_KEY', nil)
                     if stripe_key.blank?
                       render json: { ok: false, error: 'Payment provider not configured' }, status: :service_unavailable
                       return
                     end
                     Stripe.api_key = stripe_key

                     # Stable key so that a double-click or browser retry resolves to the
                     # same PaymentAttempt rather than creating a duplicate.
                     qr_idempotency_key = "checkout_qr:#{@ordr.id}"
                     qr_payment_attempt = PaymentAttempt.find_or_create_by!(idempotency_key: qr_idempotency_key) do |pa|
                       pa.ordr       = @ordr
                       pa.restaurant = @ordr.restaurant
                       pa.provider   = :stripe
                       pa.amount_cents = amount_cents
                       pa.currency   = currency
                       pa.status     = :requires_action
                       pa.charge_pattern  = :direct
                       pa.merchant_model  = :restaurant_mor
                     end
                     session = Stripe::Checkout::Session.create(
                       mode: 'payment',
                       success_url: success_url,
                       cancel_url: cancel_url,
                       client_reference_id: @ordr.id.to_s,
                       line_items: [{
                         quantity: 1,
                         price_data: {
                           currency: currency.to_s.downcase,
                           unit_amount: amount_cents,
                           product_data: { name: "#{@ordr.restaurant.name} Order #{@ordr.id}" },
                         },
                       }],
                       metadata: {
                         order_id: @ordr.id,
                         restaurant_id: @ordr.restaurant_id,
                         payment_attempt_id: qr_payment_attempt.id,
                       },
                     )
                     qr_payment_attempt.update_column(:provider_payment_id, session.id)
                     session.url
                   end

    qr = RQRCode::QRCode.new(checkout_url)
    svg = qr.as_svg(
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true,
      use_path: true,
    )

    render json: { ok: true, checkout_url: checkout_url, qr_svg: svg }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[CheckoutQR] Failed for ordr=#{@ordr.id}: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'Failed to generate payment QR code' }, status: :service_unavailable
  end

  def create_inline_payment
    authorize @ordr, :update?

    if @ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to pay' }, status: :unprocessable_content
      return
    end

    source_id = params[:source_id]
    if source_id.blank?
      render json: { ok: false, error: 'source_id is required' }, status: :unprocessable_content
      return
    end

    restaurant = @ordr.restaurant
    unless restaurant.square_provider?
      render json: { ok: false, error: 'Square is not enabled for this restaurant' }, status: :unprocessable_content
      return
    end

    currency = restaurant.currency.presence || 'USD'
    requested_amount = params[:amount_cents].to_i
    amount_cents = requested_amount.positive? ? requested_amount : total_amount_cents(@ordr)
    tip_cents = params[:tip_cents].to_i

    if amount_cents <= 0
      render json: { ok: false, error: 'Order total is zero' }, status: :unprocessable_content
      return
    end

    adapter = Payments::Providers::SquareAdapter.new(restaurant: restaurant)

    pa = PaymentAttempt.create!(
      ordr: @ordr,
      restaurant: restaurant,
      provider: :square,
      amount_cents: amount_cents + tip_cents,
      currency: currency,
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
      idempotency_key: SecureRandom.uuid,
    )

    result = adapter.create_payment!(
      payment_attempt: pa,
      ordr: @ordr,
      source_id: source_id,
      amount_cents: amount_cents,
      tip_cents: tip_cents,
      currency: currency,
      verification_token: params[:verification_token],
    )

    # The adapter already updated pa.status via map_status and pa.provider_payment_id.
    # Reload to get the actual status Square returned.
    pa.reload

    if pa.succeeded?
      OrderEvent.emit!(
        ordr: @ordr,
        event_type: 'paid',
        entity_type: 'order',
        entity_id: @ordr.id,
        source: 'staff',
        idempotency_key: "square_inline_paid:#{@ordr.id}:#{result[:payment_id]}",
        payload: { provider: 'square', payment_id: result[:payment_id] },
      )
      OrderEvent.emit!(
        ordr: @ordr,
        event_type: 'closed',
        entity_type: 'order',
        entity_id: @ordr.id,
        source: 'staff',
        idempotency_key: "square_inline_closed:#{@ordr.id}:#{result[:payment_id]}",
        payload: { provider: 'square' },
      )
      OrderEventProjector.project!(@ordr.id)
      @ordr.reload
      broadcast_state(@ordr)
    end

    Rails.logger.info(
      "[SquareInline] Payment #{pa.status} (ordr_id=#{@ordr.id} pa_id=#{pa.id} payment_id=#{result[:payment_id]})",
    )

    render json: { ok: true, status: pa.status, payment_id: result[:payment_id] }, status: :ok
  rescue Payments::Providers::SquareHttpClient::SquareApiError => e
    Rails.logger.error("[SquareInline] Failed: #{e.class}: #{e.message}")
    pa&.update(status: :failed) if pa&.persisted?
    render json: { ok: false, error: 'Payment failed' }, status: :unprocessable_content
  rescue StandardError => e
    Rails.logger.error("[SquareInline] Unexpected: #{e.class}: #{e.message}")
    pa&.update(status: :failed) if pa&.persisted?
    render json: { ok: false, error: 'Payment failed' }, status: :service_unavailable
  end

  private

  def csrf_skipped_action?
    %w[request_bill split_evenly split_plan checkout_session create_inline_payment
       cash_payment checkout_qr].include?(action_name)
  end

  def safe_session_id
    session.id.to_s.presence || (session[:sid] ||= SecureRandom.uuid).to_s
  end

  def current_customer_participant
    return @current_customer_participant if defined?(@current_customer_participant)

    @current_customer_participant = @ordr.ordrparticipants.find_by(
      role: Ordrparticipant.roles['customer'],
      sessionid: safe_session_id,
    )
  end

  def authorize_split_access!
    if current_user.present?
      authorize @ordr, :update?
      return true
    end

    if current_customer_participant.present?
      skip_authorization
      return true
    end

    skip_authorization
    render json: { ok: false, error: 'Not authorized for this split plan' }, status: :forbidden
    false
  end

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
    (ordr.ordritems.sum('ordritemprice * quantity').to_f * 100.0).round
  end

  def compute_even_split(total_cents, n)
    base = total_cents / n
    remainder = total_cents % n
    (0...n).map { |i| base + (i < remainder ? 1 : 0) }
  end

  def split_plan_payload(plan)
    plan.reload

    {
      ok: true,
      order_id: @ordr.id,
      split_plan: {
        id: plan.id,
        split_method: plan.split_method,
        plan_status: plan.plan_status,
        frozen_at: plan.frozen_at,
        participant_count: plan.participant_count,
        total_amount_cents: plan.total_allocated_cents,
        shares: plan.ordr_split_payments.order(:position).map do |sp|
          {
            id: sp.id,
            ordrparticipant_id: sp.ordrparticipant_id,
            amount_cents: sp.amount_cents,
            base_amount_cents: sp.base_amount_cents,
            tax_amount_cents: sp.tax_amount_cents,
            tip_amount_cents: sp.tip_amount_cents,
            service_charge_amount_cents: sp.service_charge_amount_cents,
            percentage_basis_points: sp.percentage_basis_points,
            status: sp.status,
            locked_at: sp.locked_at,
            item_ids: sp.ordr_split_item_assignments.order(:id).pluck(:ordritem_id),
          }
        end,
      },
    }
  end

  def create_stripe_checkout(split_payment:, amount_cents:, currency:, success_url:, cancel_url:)
    if Stripe.api_key.blank?
      key = begin
        Rails.application.credentials.stripe_secret_key
      rescue StandardError => e
        Rails.logger.warn("[OrdrPaymentsController#create_stripe_checkout] credentials.stripe_secret_key lookup failed: #{e.message}")
        nil
      end
      if key.blank?
        key = begin
          Rails.application.credentials.dig(:stripe, :secret_key) ||
            Rails.application.credentials.dig(:stripe, :api_key)
        rescue StandardError => e
          Rails.logger.warn("[OrdrPaymentsController#create_stripe_checkout] credentials dig for stripe key failed: #{e.message}")
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
      provider: :stripe,
      provider_checkout_session_id: session.id.to_s,
      provider_payment_id: session.payment_intent.to_s.presence,
    )

    render json: { ok: true, checkout_session_id: session.id.to_s, checkout_url: session.url.to_s }, status: :ok
  end

  def create_square_checkout(split_payment:, amount_cents:, currency:, success_url:, cancel_url:)
    adapter = Payments::Providers::SquareAdapter.new(restaurant: @ordr.restaurant)

    pa = PaymentAttempt.create!(
      ordr: @ordr,
      restaurant: @ordr.restaurant,
      provider: :square,
      amount_cents: amount_cents,
      currency: currency,
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
      idempotency_key: SecureRandom.uuid,
    )

    result = adapter.create_checkout_session!(
      payment_attempt: pa,
      ordr: @ordr,
      amount_cents: amount_cents,
      currency: currency,
      success_url: success_url,
      cancel_url: cancel_url,
    )

    split_payment&.update!(
      status: :pending,
      provider: :square,
      provider_checkout_session_id: result[:checkout_session_id],
      idempotency_key: pa.idempotency_key,
    )

    Rails.logger.info(
      "[SquareCheckout] Created checkout (ordr_id=#{@ordr.id} split_payment_id=#{split_payment&.id} link_id=#{result[:checkout_session_id]})",
    )

    render json: { ok: true, checkout_session_id: result[:checkout_session_id], checkout_url: result[:checkout_url] }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[SquareCheckout] Failed: #{e.class}: #{e.message}")
    pa&.update(status: :failed) if pa&.persisted?
    render json: { ok: false, error: 'Square checkout failed' }, status: :service_unavailable
  end

  def broadcast_state(ordr)
    menu = ordr.menu
    restaurant = ordr.restaurant
    tablesetting = ordr.tablesetting

    participant = begin
      ordr.ordrparticipants.find_by(sessionid: session.id.to_s)
    rescue StandardError => e
      Rails.logger.warn("[OrdrPaymentsController#broadcast_state] participant lookup failed for order=#{ordr.id}: #{e.message}")
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
    rescue StandardError => e
      Rails.logger.warn("[OrdrPaymentsController#broadcast_state] slug channel broadcast failed for order=#{ordr.id}: #{e.message}")
    end
  end
end
