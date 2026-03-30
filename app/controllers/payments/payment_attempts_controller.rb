class Payments::PaymentAttemptsController < ApplicationController
  protect_from_forgery except: [:create]
  after_action :verify_authorized

  def create
    ordr_id = params[:ordr_id].presence || params[:order_id].presence
    ordr = Ordr.find_by(id: ordr_id)

    unless ordr
      render json: { ok: false, error: 'Order not found' }, status: :not_found
      return
    end

    authorize ordr, :update?

    if ordr.status.to_s != 'billrequested'
      render json: { ok: false, error: 'Order must be billrequested to pay' }, status: :unprocessable_content
      return
    end

    success_url = url_from(params[:success_url]) || root_url
    cancel_url = url_from(params[:cancel_url]) || root_url

    provider = params[:provider].presence
    if provider.present? && !provider.to_s.in?(%w[stripe])
      render json: { ok: false, error: 'Unsupported payment provider' }, status: :unprocessable_content
      return
    end

    result = Payments::Orchestrator.new(provider: provider).create_payment_attempt!(
      ordr: ordr,
      success_url: success_url,
      cancel_url: cancel_url,
    )

    render json: {
      ok: true,
      payment_attempt_id: result.fetch(:payment_attempt).id,
      redirect_url: result.fetch(:next_action).fetch(:redirect_url),
      provider_reference: result.fetch(:provider_reference),
    }, status: :ok
  end
end
