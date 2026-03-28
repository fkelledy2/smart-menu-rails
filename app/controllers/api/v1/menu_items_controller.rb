# frozen_string_literal: true

class Api::V1::MenuItemsController < Api::V1::BaseController
  skip_after_action :verify_authorized
  before_action :set_menu, only: [:index]

  # GET /api/v1/menus/:menu_id/items
  def index
    @pagy, @menu_items = pagy(@menu.menuitems.includes(:menusection))

    render json: {
      data: @menu_items.map { |item| menu_item_json(item) },
      pagination: pagy_metadata_response(@pagy),
    }
  end

  private

  def set_menu
    @menu = Menu.find(params[:menu_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Menu not found' } }, status: :not_found
  end

  def menu_item_json(item)
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
  end
end
