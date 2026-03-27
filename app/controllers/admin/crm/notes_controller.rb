# frozen_string_literal: true

module Admin
  module Crm
    class NotesController < ::ApplicationController
      skip_around_action :switch_locale
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false

      before_action :authenticate_user!
      before_action :require_mellow_admin!
      before_action :check_feature_flag!
      before_action :set_lead

      def create
        @note = @lead.crm_lead_notes.build(note_params.merge(author: current_user))
        authorize @note

        if @note.save
          @lead.touch(:last_activity_at)
          ::Crm::LeadAuditWriter.write(
            crm_lead: @lead,
            event: 'note_added',
            actor: current_user,
            metadata: { note_id: @note.id },
          )

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to admin_crm_lead_path(@lead), notice: 'Note added.' }
          end
        else
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.replace('note_form_errors', partial: 'admin/crm/notes/errors', locals: { note: @note }) }
            format.html { redirect_to admin_crm_lead_path(@lead), alert: @note.errors.full_messages.to_sentence }
          end
        end
      end

      def destroy
        @note = @lead.crm_lead_notes.find(params[:id])
        authorize @note

        @note.destroy!
        @lead.touch(:last_activity_at)

        ::Crm::LeadAuditWriter.write(
          crm_lead: @lead,
          event: 'note_deleted',
          actor: current_user,
          metadata: { note_id: params[:id].to_i },
        )

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_crm_lead_path(@lead), notice: 'Note deleted.' }
        end
      end

      private

      def set_lead
        @lead = CrmLead.find(params[:lead_id])
      end

      def note_params
        params.require(:crm_lead_note).permit(:body)
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
