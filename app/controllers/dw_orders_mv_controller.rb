class DwOrdersMvController < ApplicationController
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
        render json: policy_scope(DwOrdersMv).limit(1000)
      end
    end
  end

  # GET /dw_orders_mv/:id
  def show
    authorize @dw_order_mv
    render json: @dw_order_mv
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
