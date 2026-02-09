class Madmin::ImpersonatesController < Madmin::ApplicationController
  before_action :require_super_admin!

  def impersonate
    user = User.find(params[:id])
    start_audit_for_member_impersonation!(user)
    impersonate_user(user)
    redirect_to root_path
  end

  def stop_impersonating
    finalize_impersonation_audit!(ended_reason: 'manual_stop')
    stop_impersonating_user
    redirect_to root_path
  end

  private

  def require_super_admin!
    return if current_user&.super_admin?

    redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
  end

  def start_audit_for_member_impersonation!(user)
    audit = ImpersonationAudit.create!(
      admin_user: current_user,
      impersonated_user: user,
      started_at: Time.current,
      expires_at: 30.minutes.from_now,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s,
    )

    session[:impersonation_audit_id] = audit.id
    session[:impersonation_expires_at] = audit.expires_at.iso8601
  end

  def finalize_impersonation_audit!(ended_reason:)
    audit_id = session[:impersonation_audit_id]
    return if audit_id.blank?

    audit = ImpersonationAudit.find_by(id: audit_id)
    return unless audit
    return if audit.ended_at.present?

    audit.update!(ended_at: Time.current, ended_reason: ended_reason)
  ensure
    session.delete(:impersonation_audit_id)
    session.delete(:impersonation_expires_at)
  end
end
