class ReceiptDeliveriesController < ApplicationController
  # Self-service action is customer-facing — no auth required.
  # Staff create action requires authentication (handled by Devise).
  skip_before_action :set_current_employee, only: [:self_service]
  skip_before_action :set_permissions, only: [:self_service]
  skip_before_action :redirect_to_onboarding_if_needed, only: [:self_service]

  before_action :authenticate_user!, only: [:create]
  before_action :set_ordr_for_staff, only: [:create]
  before_action :set_ordr_for_self_service, only: [:self_service]

  after_action :verify_authorized

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/send_receipt
  # Staff-facing: authenticated, Pundit-gated
  def create
    return feature_disabled_response unless Flipper.enabled?(:receipt_email, current_user)

    delivery_record = ReceiptDelivery.new(
      ordr: @ordr,
      restaurant: @ordr.restaurant,
    )
    authorize delivery_record

    service = ReceiptDeliveryService.new(
      ordr: @ordr,
      delivery_method: receipt_params[:delivery_method].presence || 'email',
      recipient_email: receipt_params[:recipient_email],
      recipient_phone: receipt_params[:recipient_phone],
      created_by_user: current_user,
    )

    @delivery = service.call

    respond_to do |format|
      format.html do
        flash[:notice] = 'Receipt sent successfully.'
        redirect_back_or_to(restaurant_ordrs_path(@ordr.restaurant))
      end
      format.json { render json: { status: 'ok', id: @delivery.id }, status: :created }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "send_receipt_modal_#{@ordr.id}",
          partial: 'receipt_deliveries/send_receipt_success',
          locals: { ordr: @ordr },
        )
      end
    end
  rescue ReceiptDeliveryService::DeliveryError => e
    respond_to do |format|
      format.html do
        flash[:alert] = e.message
        redirect_back_or_to(restaurant_ordrs_path(@ordr.restaurant))
      end
      format.json { render json: { error: e.message }, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "send_receipt_modal_#{@ordr.id}",
          partial: 'receipt_deliveries/send_receipt_error',
          locals: { ordr: @ordr, error: e.message },
        )
      end
    end
  end

  # POST /receipts/request
  # Customer self-service: public, rate-limited via RackAttack
  def self_service
    authorize ReceiptDelivery, :self_service?

    return feature_disabled_response unless Flipper.enabled?(:receipt_email)

    service = ReceiptDeliveryService.new(
      ordr: @ordr,
      delivery_method: 'email',
      recipient_email: receipt_params[:recipient_email],
      created_by_user: nil,
    )

    service.call

    respond_to do |format|
      format.html do
        flash[:notice] = 'Your receipt is on its way. Please check your inbox.'
        redirect_back_or_to(root_path)
      end
      format.json { render json: { status: 'ok' }, status: :created }
    end
  rescue ReceiptDeliveryService::DeliveryError => e
    respond_to do |format|
      format.html do
        flash[:alert] = e.message
        redirect_back_or_to(root_path)
      end
      format.json { render json: { error: e.message }, status: :unprocessable_content }
    end
  end

  private

  def set_ordr_for_staff
    @ordr = Ordr
      .joins(:restaurant)
      .where(restaurants: { id: params[:restaurant_id] })
      .find(params[:ordr_id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def set_ordr_for_self_service
    @ordr = Ordr.find_by(id: receipt_params[:ordr_id])
    head :not_found unless @ordr
  end

  def receipt_params
    params.permit(
      :recipient_email,
      :recipient_phone,
      :delivery_method,
      :ordr_id,
      :consent,
    )
  end

  def feature_disabled_response
    respond_to do |format|
      format.html do
        flash[:alert] = 'Receipt delivery is not available at this time.'
        redirect_back_or_to(root_path)
      end
      format.json { render json: { error: 'Feature not enabled' }, status: :service_unavailable }
      format.turbo_stream { head :service_unavailable }
    end
  end
end
