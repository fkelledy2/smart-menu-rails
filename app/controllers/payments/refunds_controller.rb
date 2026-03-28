class Payments::RefundsController < ApplicationController
  protect_from_forgery except: [:create]

  before_action :ensure_admin!

  def create
    # Scope to restaurants owned by the current admin to prevent cross-tenant refunds.
    payment_attempt = PaymentAttempt
      .joins(:restaurant)
      .where(restaurants: { id: current_user.restaurants.select(:id) })
      .find(params[:payment_attempt_id])

    if payment_attempt.status.to_s != 'succeeded'
      render json: { ok: false, error: 'Payment must be succeeded to refund' }, status: :unprocessable_content
      return
    end

    refund = Payments::Refunds::Creator.new.create_full_refund!(payment_attempt: payment_attempt)

    render json: {
      ok: true,
      payment_refund_id: refund.id,
      status: refund.status,
      provider_refund_id: refund.provider_refund_id,
    }, status: :ok
  end
end
