# frozen_string_literal: true

module Admin
  module Crm
    class LeadsController < ::ApplicationController
      skip_around_action :switch_locale
      skip_before_action :set_current_employee, raise: false
      skip_before_action :set_permissions, raise: false
      skip_before_action :redirect_to_onboarding_if_needed, raise: false

      before_action :authenticate_user!
      before_action :require_mellow_admin!
      before_action :check_feature_flag!
      before_action :set_lead, only: %i[show edit update destroy transition convert reopen]

      def index
        authorize CrmLead
        @leads_by_stage = policy_scope(CrmLead)
          .includes(:assigned_to, :restaurant, :discovered_restaurant)
          .order(last_activity_at: :desc)
          .group_by(&:stage)
        @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
        @needs_assignment_count = CrmLead.needs_assignment.count
      end

      def show
        authorize @lead
        @notes = @lead.crm_lead_notes.includes(:author).order(created_at: :desc)
        @audits = @lead.crm_lead_audits.includes(:actor).order(created_at: :desc).limit(20)
        @email_sends = @lead.crm_email_sends.includes(:sender).order(created_at: :desc)
        @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
      end

      def new
        @lead = CrmLead.new
        authorize @lead
        @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
      end

      def edit
        authorize @lead
        @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
      end

      def create
        @lead = CrmLead.new(lead_params)
        authorize @lead

        if @lead.save
          ::Crm::LeadAuditWriter.write(
            crm_lead: @lead,
            event: 'lead_created',
            actor: current_user,
          )
          redirect_to admin_crm_lead_path(@lead), notice: 'Lead created.'
        else
          @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
          render :new, status: :unprocessable_content
        end
      end

      def update
        authorize @lead

        old_attrs = @lead.attributes.slice('restaurant_name', 'contact_name', 'contact_email', 'contact_phone', 'source', 'assigned_to_id')

        if @lead.update(lead_params)
          record_field_changes(old_attrs)
          redirect_to admin_crm_lead_path(@lead), notice: 'Lead updated.'
        else
          @users = User.where('email LIKE ?', '%@mellow.menu').order(:email)
          render :edit, status: :unprocessable_content
        end
      end

      def destroy
        authorize @lead
        @lead.destroy!
        redirect_to admin_crm_leads_path, notice: 'Lead deleted.'
      end

      # PATCH /admin/crm/leads/:id/transition
      def transition
        authorize @lead, :transition?

        result = ::Crm::LeadTransitionService.call(
          lead: @lead,
          new_stage: params[:stage].to_s,
          actor: current_user,
          lost_reason: params[:lost_reason],
          lost_reason_notes: params[:lost_reason_notes],
        )

        respond_to do |format|
          if result.success?
            format.json { render json: { stage: @lead.stage }, status: :ok }
            format.html { redirect_to admin_crm_leads_path, notice: 'Stage updated.' }
          else
            format.json { render json: { error: result.error }, status: :unprocessable_content }
            format.html { redirect_to admin_crm_leads_path, alert: result.error }
          end
        end
      end

      # PATCH /admin/crm/leads/:id/convert
      def convert
        authorize @lead, :convert?

        result = ::Crm::LeadTransitionService.call(
          lead: @lead,
          new_stage: 'converted',
          actor: current_user,
          restaurant_id: params[:restaurant_id],
        )

        if result.success?
          redirect_to admin_crm_leads_path, notice: 'Lead converted and linked to restaurant.'
        else
          redirect_to admin_crm_leads_path, alert: result.error
        end
      end

      # PATCH /admin/crm/leads/:id/reopen
      def reopen
        authorize @lead, :reopen?

        result = ::Crm::LeadTransitionService.call(
          lead: @lead,
          new_stage: 'contacted',
          actor: current_user,
        )

        if result.success?
          redirect_to admin_crm_leads_path, notice: 'Lead reopened.'
        else
          redirect_to admin_crm_leads_path, alert: result.error
        end
      end

      private

      def set_lead
        @lead = CrmLead.find_by(id: params[:id])
        head :not_found unless @lead
      end

      def lead_params
        params.require(:crm_lead).permit(
          :restaurant_name,
          :contact_name,
          :contact_email,
          :contact_phone,
          :source,
          :assigned_to_id,
        )
      end

      def require_mellow_admin!
        return if current_user&.super_admin? && current_user&.email.to_s.end_with?('@mellow.menu')

        redirect_to root_path, alert: 'Access denied. mellow.menu staff only.', status: :see_other
      end

      def check_feature_flag!
        return if Flipper.enabled?(:crm_sales_funnel, current_user)

        redirect_to root_path, alert: 'CRM feature not enabled.', status: :see_other
      end

      def record_field_changes(old_attrs)
        %w[restaurant_name contact_name contact_email contact_phone source assigned_to_id].each do |field|
          old_val = old_attrs[field]
          new_val = @lead.send(field)
          next if old_val.to_s == new_val.to_s

          ::Crm::LeadAuditWriter.write(
            crm_lead: @lead,
            event: 'field_updated',
            actor: current_user,
            field_name: field,
            from_value: old_val,
            to_value: new_val,
          )
        end
      end
    end
  end
end
