module DiningSessionGate
  extend ActiveSupport::Concern

  included do
    helper_method :current_dining_session
  end

  # Call this as a before_action on any order mutation endpoint.
  # Skipped for authenticated staff users (employees bypass the session gate).
  # When qr_security_v1 Flipper flag is disabled, the gate is a no-op.
  def require_valid_dining_session!
    return unless Flipper.enabled?(:qr_security_v1)
    return if user_signed_in? && @current_employee.present?

    ds = current_dining_session
    return if ds

    Rails.logger.warn(
      "[DiningSessionGate] No valid dining session for request " \
      "session_token=#{session[:dining_session_token].to_s.first(8)}... ip=#{request.remote_ip}",
    )

    respond_to do |format|
      format.json { render json: { error: 'session_expired', message: 'Your dining session has expired. Please re-scan the QR code.' }, status: :unauthorized }
      format.html { redirect_to session_expired_path, alert: 'Your session has expired. Please re-scan the QR code.' }
      format.any  { head :unauthorized }
    end
  end

  def current_dining_session
    return @current_dining_session if defined?(@current_dining_session)

    token = session[:dining_session_token]
    return (@current_dining_session = nil) if token.blank?

    ds = DiningSession.valid.find_by(session_token: token)
    ds&.touch_activity!
    @current_dining_session = ds
  end
end
