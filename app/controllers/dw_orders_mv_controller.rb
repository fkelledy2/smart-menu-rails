class DwOrdersMvController < ApplicationController
  include QueryCacheable

  before_action :authenticate_user!
  before_action :set_dw_order_mv, only: [:show]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /dw_orders_mv
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json do
        # Cache order analytics data with user scoping
        orders_data = cache_order_analytics('dw_orders_index', force_refresh: force_cache_refresh?) do
          policy_scope(DwOrdersMv).limit(1000).to_a
        end

        render json: orders_data
      end
    end
  end

  # GET /dw_orders_mv/:id
  def show
    authorize @dw_order_mv

    # Cache individual order data
    order_data = cache_query(cache_type: :order_analytics, key_parts: ['dw_order', params[:id]],
                             force_refresh: force_cache_refresh?,) do
      @dw_order_mv.as_json
    end

    render json: order_data
  end

  # Prevent modification actions
  def create = head(:method_not_allowed)
  def update = head(:method_not_allowed)
  def destroy = head(:method_not_allowed)

  private

  def set_dw_order_mv
    @dw_order_mv = DwOrdersMv.find(params[:id])
  end
end
