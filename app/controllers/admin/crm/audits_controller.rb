# frozen_string_literal: true

module Admin
  module Crm
    class AuditsController < ::ApplicationController
      skip_around_action :switch_locale
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false

      before_action :authenticate_user!
      before_action :require_mellow_admin!
      before_action :check_feature_flag!
      before_action :set_lead

      def index
        authorize @lead, :show?
        @audits = @lead.crm_lead_audits
          .includes(:actor)
          .order(created_at: :desc)
      end

      private

      def set_lead
        @lead = CrmLead.find(params[:lead_id])
      end

      def require_mellow_admin!
        return if current_user&.admin? && current_user&.email.to_s.end_with?('@mellow.menu')

        redirect_to root_path, alert: 'Access denied.', status: :see_other
      end

      def check_feature_flag!
        return if Flipper.enabled?(:crm_sales_funnel, current_user)

        redirect_to root_path, alert: 'CRM feature not enabled.', status: :see_other
      end
    end
  end
end
