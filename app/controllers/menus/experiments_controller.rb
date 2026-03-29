# frozen_string_literal: true

module Menus
  # Manages A/B experiments for a menu. Scoped under a restaurant and menu.
  class ExperimentsController < BaseController
    before_action :authenticate_user!
    before_action :set_menu
    before_action :set_experiment, only: %i[show edit update destroy pause end_experiment]

    after_action :verify_authorized

    # GET /restaurants/:restaurant_id/menus/:menu_id/experiments
    def index
      authorize MenuExperiment
      @experiments = policy_scope(MenuExperiment)
        .where(menu: @menu)
        .includes(:control_version, :variant_version, :created_by_user)
        .order(created_at: :desc)
      @experiment_stats = build_experiment_stats(@experiments)
    end

    # GET /restaurants/:restaurant_id/menus/:menu_id/experiments/:id
    def show
      authorize @experiment
      @exposure_counts = exposure_counts_for(@experiment)
      @order_counts = order_counts_for(@experiment)
    end

    # GET /restaurants/:restaurant_id/menus/:menu_id/experiments/new
    def new
      authorize MenuExperiment
      @experiment = MenuExperiment.new(menu: @menu)
      @versions = @menu.menu_versions.order(version_number: :desc)
    end

    # GET /restaurants/:restaurant_id/menus/:menu_id/experiments/:id/edit
    def edit
      authorize @experiment
      @versions = @menu.menu_versions.order(version_number: :desc)
    end

    # POST /restaurants/:restaurant_id/menus/:menu_id/experiments
    def create
      authorize MenuExperiment
      @experiment = MenuExperiment.new(experiment_params)
      @experiment.menu = @menu
      @experiment.created_by_user = current_user

      if @experiment.save
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                        notice: t('menu_experiments.flash.created')
          end
          format.turbo_stream do
            flash.now[:notice] = t('menu_experiments.flash.created')
            render turbo_stream: [
              turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
              turbo_stream.replace('menu_experiments_list', partial: 'menus/experiments/list',
                                                            locals: { experiments: load_experiments, experiment_stats: {} },),
            ]
          end
        end
      else
        @versions = @menu.menu_versions.order(version_number: :desc)
        respond_to do |format|
          format.html { render :new, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = @experiment.errors.full_messages.to_sentence
            render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
                   status: :unprocessable_content
          end
        end
      end
    end

    # PATCH/PUT /restaurants/:restaurant_id/menus/:menu_id/experiments/:id
    def update
      authorize @experiment

      if @experiment.update(experiment_update_params)
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiment_path(@restaurant, @menu, @experiment),
                        notice: t('menu_experiments.flash.updated')
          end
          format.turbo_stream do
            flash.now[:notice] = t('menu_experiments.flash.updated')
            render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices')
          end
        end
      else
        @versions = @menu.menu_versions.order(version_number: :desc)
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_content }
          format.turbo_stream do
            flash.now[:alert] = @experiment.errors.full_messages.to_sentence
            render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
                   status: :unprocessable_content
          end
        end
      end
    end

    # PATCH /restaurants/:restaurant_id/menus/:menu_id/experiments/:id/pause
    def pause
      authorize @experiment, :pause?

      if @experiment.status_active?
        @experiment.update!(status: :paused)
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                        notice: t('menu_experiments.flash.paused')
          end
          format.turbo_stream do
            flash.now[:notice] = t('menu_experiments.flash.paused')
            render turbo_stream: [
              turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
              turbo_stream.replace("experiment_#{@experiment.id}_status",
                                   partial: 'menus/experiments/status_badge',
                                   locals: { experiment: @experiment },),
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                        alert: t('menu_experiments.flash.not_pausable')
          end
          format.turbo_stream do
            flash.now[:alert] = t('menu_experiments.flash.not_pausable')
            render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
                   status: :unprocessable_content
          end
        end
      end
    end

    # PATCH /restaurants/:restaurant_id/menus/:menu_id/experiments/:id/end
    def end_experiment
      authorize @experiment, :end_experiment?

      unless @experiment.status_ended?
        @experiment.update!(status: :ended)
      end

      respond_to do |format|
        format.html do
          redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                      notice: t('menu_experiments.flash.ended')
        end
        format.turbo_stream do
          flash.now[:notice] = t('menu_experiments.flash.ended')
          render turbo_stream: [
            turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
            turbo_stream.replace("experiment_#{@experiment.id}_status",
                                 partial: 'menus/experiments/status_badge',
                                 locals: { experiment: @experiment },),
          ]
        end
      end
    end

    # DELETE /restaurants/:restaurant_id/menus/:menu_id/experiments/:id
    def destroy
      authorize @experiment

      if @experiment.status_draft?
        @experiment.destroy!
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                        notice: t('menu_experiments.flash.deleted'), status: :see_other
          end
          format.turbo_stream do
            flash.now[:notice] = t('menu_experiments.flash.deleted')
            render turbo_stream: [
              turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
              turbo_stream.remove("experiment_#{@experiment.id}"),
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to restaurant_menu_experiments_path(@restaurant, @menu),
                        alert: t('menu_experiments.flash.not_deletable')
          end
          format.turbo_stream do
            flash.now[:alert] = t('menu_experiments.flash.not_deletable')
            render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices'),
                   status: :unprocessable_content
          end
        end
      end
    end

    private

    def set_experiment
      @experiment = MenuExperiment.where(menu: @menu).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to restaurant_menu_experiments_path(@restaurant, @menu), alert: 'Experiment not found' }
        format.turbo_stream { head :not_found }
      end
    end

    def load_experiments
      policy_scope(MenuExperiment)
        .where(menu: @menu)
        .includes(:control_version, :variant_version, :created_by_user)
        .order(created_at: :desc)
    end

    def build_experiment_stats(experiments)
      return {} if experiments.empty?

      experiment_ids = experiments.map(&:id)
      counts = MenuExperimentExposure
        .where(menu_experiment_id: experiment_ids)
        .group(:menu_experiment_id, :assigned_version_id)
        .count

      experiments.each_with_object({}) do |exp, h|
        h[exp.id] = {
          control: counts[[exp.id, exp.control_version_id]] || 0,
          variant: counts[[exp.id, exp.variant_version_id]] || 0,
        }
      end
    end

    def exposure_counts_for(experiment)
      MenuExperimentExposure
        .where(menu_experiment: experiment)
        .group(:assigned_version_id)
        .count
    end

    def order_counts_for(experiment)
      # Join dining_sessions that were assigned to this experiment → their ordrs
      # Uses the read replica for analytics
      DiningSession.on_replica do
        DiningSession
          .joins('INNER JOIN ordrs ON ordrs.tablesetting_id = dining_sessions.tablesetting_id')
          .where(menu_experiment: experiment)
          .where('ordrs.created_at BETWEEN ? AND ?', experiment.starts_at, experiment.ends_at)
          .group(:assigned_version_id)
          .count
      end
    rescue StandardError => e
      Rails.logger.warn("[Menus::ExperimentsController#order_counts_for] #{e.class}: #{e.message}")
      {}
    end

    # Params permitted on create — allocation_pct set on create and locked thereafter
    def experiment_params
      params.require(:menu_experiment).permit(
        :control_version_id,
        :variant_version_id,
        :allocation_pct,
        :starts_at,
        :ends_at,
        :status,
      )
    end

    # On update, allocation_pct is excluded once active (model validates this too)
    def experiment_update_params
      permitted = %i[starts_at ends_at status]
      permitted << :allocation_pct unless @experiment.status_active?
      params.require(:menu_experiment).permit(*permitted)
    end
  end
end
