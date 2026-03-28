# frozen_string_literal: true

class Api::V1::OrdersController < Api::V1::BaseController
  before_action :set_restaurant, only: %i[index create]
  before_action :set_order, only: %i[show update destroy]
  before_action :enforce_orders_scope!, only: %i[index show create update destroy]

  private

  def enforce_orders_scope!
    return unless api_jwt_request?

    if request.get? || request.head?
      enforce_scope!('orders:read')
    else
      enforce_scope!('orders:write')
    end
  end

  public

  # GET /api/v1/restaurants/:restaurant_id/orders
  def index
    authorize @restaurant

    scope = @restaurant.ordrs.includes(:ordritems)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @orders = pagy(scope)

    render json: {
      data: @orders.map { |order| order_json(order) },
      pagination: pagy_metadata_response(@pagy),
    }
  end

  # GET /api/v1/orders/:id
  def show
    authorize @order if current_user

    render json: order_with_items_json(@order)
  end

  # POST /api/v1/restaurants/:restaurant_id/orders
  def create
    @order = @restaurant.ordrs.build(order_params)
    authorize @order

    if @order.save
      # Create order items
      if params[:items].present?
        params[:items].each do |item_params|
          menu_item = Menuitem
            .joins(menusection: :menu)
            .where(menus: { restaurant_id: @restaurant.id })
            .find(item_params[:menu_item_id])
          @order.ordritems.create!(
            menuitem: menu_item,
            quantity: item_params[:quantity],
            unit_price: menu_item.price,
            total_price: menu_item.price * item_params[:quantity].to_i,
            special_instructions: item_params[:special_instructions],
          )
        end

      end

      render json: order_with_items_json(@order), status: :created
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @order.errors.full_messages.join(', ') } },
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/orders/:id
  def update
    authorize @order

    if @order.update(order_update_params)
      render json: order_json(@order)
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @order.errors.full_messages.join(', ') } },
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/orders/:id
  def destroy
    authorize @order
    @order.destroy
    head :no_content
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Restaurant not found' } }, status: :not_found
  end

  def set_order
    @order = Ordr.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Order not found' } }, status: :not_found
  end

  def order_params
    params.permit(:tablesetting_id, :menu_id, :employee_id, :status)
  end

  def order_update_params
    params.permit(:status)
  end

  def order_json(order)
    {
      id: order.id,
      restaurant_id: order.restaurant_id,
      status: order.status,
      nett: order.nett || 0,
      tax: order.tax || 0,
      service: order.service || 0,
      tip: order.tip || 0,
      gross: order.gross || 0,
      created_at: order.created_at,
      updated_at: order.updated_at,
    }
  end

  def order_with_items_json(order)
    order_data = order_json(order)
    order_data[:items] = order.ordritems.includes(:menuitem).map do |item|
      {
        id: item.id,
        order_id: item.ordr_id,
        menu_item_id: item.menuitem_id,
        menu_item_name: item.menuitem&.name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price,
        special_instructions: item.special_instructions,
        created_at: item.created_at,
        updated_at: item.updated_at,
      }
    end
    order_data
  end
end
