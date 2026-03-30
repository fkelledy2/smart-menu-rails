class AutoPayController < ApplicationController
  include CsrfSafeGuestActions

  skip_before_action :verify_authenticity_token,
                     only: %i[store_payment_method remove_payment_method toggle_auto_pay view_bill setup_intent]

  before_action :set_restaurant
  before_action :set_ordr

  after_action :verify_authorized

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/payment_methods
  # Customer stores a Stripe PaymentMethod ID (no raw card data).
  def store_payment_method
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    authorize @ordr, :payment_method?

    payment_method_id = params[:payment_method_id].to_s.strip
    if payment_method_id.blank?
      render json: { ok: false, error: 'payment_method_id is required' }, status: :unprocessable_content
      return
    end

    unless payment_method_id.start_with?('pm_')
      render json: { ok: false, error: 'Invalid payment_method_id format' }, status: :unprocessable_content
      return
    end

    @ordr.update!(
      payment_method_ref: payment_method_id,
      payment_provider: 'stripe',
      payment_on_file: true,
      payment_on_file_at: Time.current,
    )

    log_ordr_action(:payment_method_added)

    render json: { ok: true, payment_on_file: true }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { ok: false, error: e.message }, status: :unprocessable_content
  end

  # DELETE /restaurants/:restaurant_id/ordrs/:ordr_id/payment_methods
  # Customer removes their stored payment method.
  def remove_payment_method
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    authorize @ordr, :payment_method?

    @ordr.update!(
      payment_method_ref: nil,
      payment_provider: nil,
      payment_on_file: false,
      payment_on_file_at: nil,
      auto_pay_enabled: false,
      auto_pay_consent_at: nil,
    )

    log_ordr_action(:payment_method_removed)

    render json: { ok: true, payment_on_file: false }, status: :ok
  end

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/auto_pay
  # Customer enables or disables auto-pay.
  # Body: { enabled: true } or { enabled: false }
  def toggle_auto_pay
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    authorize @ordr, :auto_pay?

    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])

    if enabled
      unless @ordr.payment_on_file?
        render json: { ok: false, error: 'Cannot enable auto-pay without a payment method on file' },
               status: :unprocessable_content
        return
      end

      @ordr.update!(
        auto_pay_enabled: true,
        auto_pay_consent_at: Time.current,
      )

      log_ordr_action(:auto_pay_enabled)
    else
      @ordr.update!(
        auto_pay_enabled: false,
        auto_pay_consent_at: nil,
      )

      log_ordr_action(:auto_pay_disabled)
    end

    render json: {
      ok: true,
      auto_pay_enabled: @ordr.auto_pay_enabled,
      auto_pay_consent_at: @ordr.auto_pay_consent_at&.iso8601,
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { ok: false, error: e.message }, status: :unprocessable_content
  end

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/view_bill
  # Records that the customer has viewed their bill. Idempotent.
  def view_bill
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    authorize @ordr, :view_bill?

    if @ordr.viewed_bill_at.nil?
      @ordr.update!(viewed_bill_at: Time.current)
      log_ordr_action(:bill_viewed)
    end

    render json: {
      ok: true,
      viewed_bill_at: @ordr.viewed_bill_at&.iso8601,
      bill: bill_payload,
    }, status: :ok
  end

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/payments/setup_intent
  # Customer-facing: create a Stripe SetupIntent so the frontend can collect and save a card.
  # Returns { client_secret: String }. No amount is charged at this step.
  def setup_intent
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    authorize @ordr, :payment_method?

    client_secret = Payments::SetupIntentService.create_for_ordr(@ordr)
    render json: { ok: true, client_secret: client_secret }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[AutoPayController#setup_intent] Failed for ordr=#{@ordr.id}: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'Could not create payment setup session.' }, status: :service_unavailable
  end

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/capture
  # Staff-only manual capture ("Charge Now" button).
  def capture
    return feature_disabled_response unless auto_pay_enabled_for_restaurant?

    unless current_user || @current_employee
      skip_authorization
      render json: { ok: false, error: 'Staff authentication required' }, status: :forbidden
      return
    end

    authorize @ordr, :capture?

    unless @ordr.payment_on_file?
      render json: { ok: false, error: 'No payment method on file' }, status: :unprocessable_content
      return
    end

    if @ordr.auto_pay_status == 'succeeded' || @ordr.paid? || @ordr.closed?
      render json: { ok: true, status: @ordr.status.to_s, message: 'Already captured' }, status: :ok
      return
    end

    result = AutoPay::CaptureService.new(ordr: @ordr).call
    @ordr.reload

    log_ordr_action(:manual_capture)

    if result.success?
      render json: { ok: true, status: @ordr.status.to_s }, status: :ok
    else
      render json: { ok: false, error: result.error, status: @ordr.status.to_s },
             status: :unprocessable_content
    end
  end

  private

  def csrf_skipped_action?
    %w[store_payment_method remove_payment_method toggle_auto_pay view_bill setup_intent].include?(action_name)
  end

  def set_restaurant
    return unless params[:restaurant_id]

    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
    head :not_found unless @restaurant
  end

  def set_ordr
    @ordr = Ordr.find_by(id: params[:id])
    unless @ordr
      skip_authorization
      render json: { ok: false, error: 'Order not found' }, status: :not_found
      return
    end

    return unless @restaurant && @ordr.restaurant_id != @restaurant.id

    skip_authorization
    render json: { ok: false, error: 'Order not found for restaurant' }, status: :not_found
  end

  def auto_pay_enabled_for_restaurant?
    Flipper.enabled?(:auto_pay, @ordr.restaurant)
  end

  def feature_disabled_response
    skip_authorization
    render json: { ok: false, error: 'Auto Pay is not enabled for this restaurant' },
           status: :service_unavailable
  end

  def bill_payload
    {
      items: @ordr.ordritems.map do |item|
        {
          id: item.id,
          name: item.menuitem&.name,
          quantity: item.quantity,
          unit_price: item.ordritemprice,
          total: (item.ordritemprice.to_f * item.quantity.to_f).round(2),
        }
      end,
      nett: @ordr.nett,
      tax: @ordr.tax,
      service: @ordr.service,
      tip: @ordr.tip,
      gross: @ordr.gross,
      currency: @ordr.restaurant.currency.presence || 'USD',
    }
  end

  def log_ordr_action(action_type)
    participant = @ordr.ordrparticipants.first
    return unless participant

    @ordr.ordractions.create!(
      ordrparticipant_id: participant.id,
      ordr_id: @ordr.id,
      action: action_type,
    )
  rescue StandardError => e
    Rails.logger.warn(
      "[AutoPayController#log_ordr_action] failed for ordr=#{@ordr.id}: #{e.message}",
    )
  end
end
