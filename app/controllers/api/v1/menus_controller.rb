# frozen_string_literal: true

class Api::V1::MenusController < Api::V1::BaseController
  before_action :set_restaurant, only: %i[index create]
  before_action :set_menu, only: %i[show update destroy]
  before_action :authenticate_user!, except: %i[show index]

  # GET /api/v1/restaurants/:restaurant_id/menus
  def index
    @menus = @restaurant.menus.includes(:menusections)

    render json: @menus.map { |menu| menu_json(menu) }
  end

  # GET /api/v1/menus/:id
  def show
    authorize @menu if current_user

    render json: menu_with_items_json(@menu)
  end

  # POST /api/v1/restaurants/:restaurant_id/menus
  def create
    @menu = @restaurant.menus.build(menu_params)
    authorize @menu

    if @menu.save
      render json: menu_json(@menu), status: :created
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @menu.errors.full_messages.join(', ') } },
             status: :unprocessable_content
    end
  end

  # PATCH/PUT /api/v1/menus/:id
  def update
    authorize @menu

    if @menu.update(menu_params)
      render json: menu_json(@menu)
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @menu.errors.full_messages.join(', ') } },
             status: :unprocessable_content
    end
  end

  # DELETE /api/v1/menus/:id
  def destroy
    authorize @menu
    @menu.destroy
    head :no_content
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Restaurant not found' } }, status: :not_found
  end

  def set_menu
    @menu = Menu.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Menu not found' } }, status: :not_found
  end

  def menu_params
    params.require(:menu).permit(:name, :description, :active)
  end

  def menu_json(menu)
    {
      id: menu.id,
      name: menu.name,
      description: menu.description,
      restaurant_id: menu.restaurant_id,
      active: menu.active?,
      created_at: menu.created_at,
      updated_at: menu.updated_at,
    }
  end

  def menu_with_items_json(menu)
    menu_data = menu_json(menu)
    menu_data[:sections] = menu.menusections.includes(:menuitems).map do |section|
      {
        id: section.id,
        name: section.name,
        description: section.description,
        position: section.position,
        items: section.menuitems.map do |item|
          {
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price,
            menu_section_id: item.menusection_id,
            active: item.active?,
            allergens: item.allergens || [],
            dietary_info: {
              vegetarian: item.vegetarian?,
              vegan: item.vegan?,
              gluten_free: item.gluten_free?,
            },
            created_at: item.created_at,
            updated_at: item.updated_at,
          }
        end,
      }
    end
    menu_data
  end
end
