# frozen_string_literal: true

module Admin
  module Crm
    class EmailSendsController < ::ApplicationController
      skip_around_action :switch_locale
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false

      before_action :authenticate_user!
      before_action :require_mellow_admin!
      before_action :check_feature_flag!
      before_action :set_lead

      def new
        @email_send = CrmEmailSend.new(to_email: @lead.contact_email)
        authorize @email_send
      end

      def create
        @email_send = CrmEmailSend.new(email_send_params.merge(crm_lead: @lead, sender: current_user))
        authorize @email_send

        ::Crm::SendLeadEmailJob.perform_later(
          crm_lead_id: @lead.id,
          sender_id: current_user.id,
          to_email: email_send_params[:to_email],
          subject: email_send_params[:subject],
          body_html: email_send_params[:body_html],
          body_text: email_send_params[:body_text],
          job_idempotency_key: SecureRandom.uuid,
        )

        redirect_to admin_crm_lead_path(@lead), notice: 'Email queued for delivery.'
      end

      private

      def set_lead
        @lead = CrmLead.find(params[:lead_id])
      end

      def email_send_params
        params.require(:crm_email_send).permit(:to_email, :subject, :body_html, :body_text)
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
