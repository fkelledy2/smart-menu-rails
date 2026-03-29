class MetricsController < ApplicationController
  include QueryCacheable

  before_action :authenticate_user!
  before_action :set_metric, only: %i[edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /metrics or /metrics.json
  def index
    scope = policy_scope(Metric)

    # Cache user-scoped metrics list
    @metrics = cache_query(cache_type: :user_analytics, key_parts: ['metrics_list'],
                           force_refresh: force_cache_refresh?,) do
      scope.limit(100).to_a
    end
  end

  # GET /metrics/1 or /metrics/1.json
  def show
    @metric = cache_query(cache_type: :user_analytics, key_parts: ['metric_show', params[:id]],
                          force_refresh: force_cache_refresh?,) do
      metric = Metric.find(params[:id])
      authorize metric
      metric
    end

    authorize @metric
  end

  # GET /metrics/new
  def new
    @metric = Metric.new
    authorize @metric
  end

  # GET /metrics/1/edit
  def edit
    authorize @metric
  end

  # POST /metrics or /metrics.json
  def create
    @metric = Metric.new(metric_params)
    authorize @metric

    respond_to do |format|
      if @metric.save
        format_html = t('common.flash.created', resource: t('activerecord.models.metric'))
        format.html { redirect_to metric_url(@metric), notice: format_html }
        format.json { render :show, status: :created, location: @metric }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @metric.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /metrics/1 or /metrics/1.json
  def update
    authorize @metric

    respond_to do |format|
      if @metric.update(metric_params)
        format.html do
          redirect_to metric_url(@metric), notice: t('common.flash.updated', resource: t('activerecord.models.metric'))
        end
        format.json { render :show, status: :ok, location: @metric }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @metric.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /metrics/1 or /metrics/1.json
  def destroy
    authorize @metric

    @metric.destroy!

    respond_to do |format|
      format.html do
        redirect_to metrics_url, notice: t('common.flash.deleted', resource: t('activerecord.models.metric'))
      end
      format.json { head :no_content }
    end
  end

  private

  def set_metric
    @metric = Metric.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def metric_params
    params.fetch(:metric, {})
  end
end
