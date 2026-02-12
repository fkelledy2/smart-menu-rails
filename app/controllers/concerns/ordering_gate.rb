module OrderingGate
  extend ActiveSupport::Concern

  private

  # Call this before allowing order creation or payment processing.
  # Returns true if ordering is allowed, or renders an error and returns false.
  def ensure_ordering_enabled!(restaurant)
    return true if current_user&.super_admin?
    return true if restaurant.nil?
    return true if restaurant.ordering_enabled?
    return true unless restaurant.respond_to?(:claim_status)
    return true unless restaurant.unclaimed?

    respond_to do |format|
      format.html do
        redirect_back_or_to root_path,
                            alert: 'Ordering is not available for this restaurant yet.'
      end
      format.json do
        render json: { error: 'ordering_disabled', message: 'Ordering is not available for this restaurant.' },
               status: :forbidden
      end
    end

    false
  end

  def ensure_payments_enabled!(restaurant)
    return true if restaurant.nil?
    return true if restaurant.payments_enabled?

    respond_to do |format|
      format.html do
        redirect_back_or_to root_path,
                            alert: 'Payments are not available for this restaurant yet.'
      end
      format.json do
        render json: { error: 'payments_disabled', message: 'Payments are not available for this restaurant.' },
               status: :forbidden
      end
    end

    false
  end
end
