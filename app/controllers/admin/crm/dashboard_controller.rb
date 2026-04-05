# frozen_string_literal: true

module Admin
  module Crm
    class DashboardController < ::ApplicationController
      skip_around_action :switch_locale
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false

      before_action :authenticate_user!
      before_action :require_mellow_admin!
      before_action :check_feature_flag!

      def index
        authorize CrmLead, :index?

        @total_leads        = CrmLead.count
        @leads_last_30_days = CrmLead.where('created_at >= ?', 30.days.ago).count
        @unassigned_count   = CrmLead.unassigned.where.not(stage: %w[converted lost]).count
        @converted_count    = CrmLead.where(stage: 'converted').count

        # Source breakdown for last 30 days
        @source_counts = CrmLead
          .where('created_at >= ?', 30.days.ago)
          .group(:source)
          .count
          .sort_by { |_, count| -count }

        # Stage breakdown
        @stage_counts = CrmLead
          .where.not(stage: 'lost')
          .group(:stage)
          .count

        # Inbound leads pending follow-up
        @inbound_pending = CrmLead
          .tagged_inbound
          .where(stage: %w[new contacted])
          .count
      end

      private

      def require_mellow_admin!
        return if current_user&.super_admin? && current_user&.email.to_s.end_with?('@mellow.menu')

        redirect_to root_path, alert: 'Access denied. mellow.menu staff only.', status: :see_other
      end

      def check_feature_flag!
        return if Flipper.enabled?(:crm_sales_funnel, current_user)

        redirect_to root_path, alert: 'CRM feature not enabled.', status: :see_other
      end
    end
  end
end
