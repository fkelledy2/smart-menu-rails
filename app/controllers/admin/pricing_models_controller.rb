# frozen_string_literal: true

module Admin
  class PricingModelsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_pricing_model, only: %i[show edit update destroy preview publish]

    def index
      authorize PricingModel, :index?
      @models = policy_scope(PricingModel).ordered
    end

    def show
      authorize @model
    end

    def new
      authorize PricingModel, :create?

      @model = PricingModel.new(
        currency: 'EUR',
        status: :draft,
      )
    end

    def edit
      authorize @model

      unless @model.draft?
        redirect_to admin_pricing_model_path(@model), alert: 'Published models cannot be edited.'
      end
    end

    def create
      authorize PricingModel, :create?

      @model = PricingModel.new(model_params)

      if @model.save
        redirect_to admin_pricing_model_path(@model), notice: 'Pricing model created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @model

      if @model.immutable?
        redirect_to admin_pricing_model_path(@model), alert: 'Published models cannot be edited.'
        return
      end

      if @model.update(model_params)
        redirect_to admin_pricing_model_path(@model), notice: 'Pricing model updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @model

      if @model.immutable?
        redirect_to admin_pricing_models_path, alert: 'Published models cannot be deleted.'
        return
      end

      @model.destroy!
      redirect_to admin_pricing_models_path, notice: 'Draft pricing model deleted.'
    end

    # GET /admin/pricing_models/:id/preview
    # Compiles without saving Stripe prices; shows computed plan prices.
    def preview
      authorize @model, :preview?

      compile_result = Pricing::ModelCompiler.compile(pricing_model: @model)

      if compile_result.success?
        @plan_prices = @model.pricing_model_plan_prices.includes(:plan).ordered
        @margin_engine_result = compute_preview_result
      else
        flash.now[:alert] = compile_result.errors.join(', ')
      end

      render :preview
    end

    # POST /admin/pricing_models/:id/publish
    def publish
      authorize @model, :publish?

      result = Pricing::ModelPublisher.publish(
        pricing_model: @model,
        published_by: current_user,
        reason: params[:reason],
      )

      if result.success?
        redirect_to admin_pricing_model_path(@model), notice: 'Pricing model published and Stripe prices created.'
      else
        flash.now[:alert] = result.errors.join(', ')
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_pricing_model
      @model = PricingModel.find(params[:id])
    end

    def model_params
      params.require(:pricing_model).permit(
        :version, :currency, :publish_reason,
        inputs_json: %i[total_cost_cents target_gross_margin_pct currency],
      ).tap do |p|
        # Accept flat inputs params for the form
        if params[:pricing_model][:inputs_total_cost_cents].present? ||
           params[:pricing_model][:inputs_target_gross_margin_pct].present?
          p[:inputs_json] = {
            'total_cost_cents' => params.dig(:pricing_model, :inputs_total_cost_cents).to_i,
            'target_gross_margin_pct' => params.dig(:pricing_model, :inputs_target_gross_margin_pct).to_f,
            'currency' => params.dig(:pricing_model, :currency) || 'EUR',
          }
        end
      end
    end

    def compute_preview_result
      inputs = @model.inputs
      return nil unless inputs['total_cost_cents'].to_i.positive?

      CostInsights::MarginEngine.compute(
        total_cost_cents: inputs['total_cost_cents'].to_i,
        target_margin_pct: inputs['target_gross_margin_pct'].to_f,
        currency: inputs['currency'] || @model.currency,
      )
    rescue ArgumentError
      nil
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied.', status: :see_other
    end
  end
end
