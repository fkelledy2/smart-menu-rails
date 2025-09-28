class DwOrdersMvController < ApplicationController
  # GET /dw_orders_mv
  def index
    respond_to do |format|
      format.html # renders index.html.erb
      format.json do
        render json: DwOrdersMv.limit(1000)
      end
    end
  end

  # GET /dw_orders_mv/:id
  def show
    @dw_order_mv = DwOrdersMv.find(params[:id])
    render json: @dw_order_mv
  end

  # Prevent modification actions
  def create = head(:method_not_allowed)
  def update = head(:method_not_allowed)
  def destroy = head(:method_not_allowed)
end
