module Admin
  class ImpersonationsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :require_super_admin!

    def new; end

    def create
      query = params[:query].to_s.strip
      if query.blank?
        redirect_back_or_to(new_admin_impersonation_path, alert: 'User email or id is required', status: :see_other)
        return
      end

      user = find_user_for_impersonation(query)
      unless user
        redirect_back_or_to(new_admin_impersonation_path, alert: 'User not found', status: :see_other)
        return
      end

      # Alert on rapid impersonation (potential insider threat)
      recent_count = ImpersonationAudit.where(admin_user: current_user)
                                       .where('started_at > ?', 1.hour.ago)
                                       .count
      if recent_count >= 5
        Rails.logger.warn("[SECURITY] Rapid impersonation detected: admin=#{current_user.id} (#{current_user.email}) " \
                          "has impersonated #{recent_count} users in the last hour")
      end

      audit = ImpersonationAudit.create!(
        admin_user: current_user,
        impersonated_user: user,
        started_at: Time.current,
        expires_at: 30.minutes.from_now,
        ip_address: request.remote_ip,
        user_agent: request.user_agent.to_s,
        reason: params[:reason].to_s.presence,
      )

      session[:impersonation_audit_id] = audit.id
      session[:impersonation_expires_at] = audit.expires_at.iso8601

      impersonate_user(user)
      redirect_to root_path
    end

    def destroy
      finalize_impersonation_audit!(ended_reason: 'manual_stop')
      stop_impersonating_user
      redirect_to root_path
    end

    private

    def require_super_admin!
      return if request.env['require_super_admin_running']

      request.env['require_super_admin_running'] = true

      user = if respond_to?(:true_user) && true_user.present?
               true_user
             else
               current_user
             end

      return if user&.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
    ensure
      request.env['require_super_admin_running'] = false
    end

    def find_user_for_impersonation(query)
      if query.match?(/\A\d+\z/)
        User.find_by(id: query.to_i)
      else
        User.find_by(email: query)
      end
    end
  end
end
