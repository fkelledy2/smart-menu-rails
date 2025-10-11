# frozen_string_literal: true

class Api::V1::RestaurantsController < Api::V1::BaseController
  before_action :set_restaurant, only: %i[show update destroy]
  before_action :authenticate_user!, except: %i[index show]

  # GET /api/v1/restaurants
  def index
    @restaurants = Restaurant.includes(:user).page(params[:page]).per(20)

    render json: @restaurants.map { |restaurant|
      {
        id: restaurant.id,
        name: restaurant.name,
        description: restaurant.description,
        address: restaurant.address,
        phone: restaurant.phone,
        email: restaurant.email,
        website: restaurant.website,
        currency: restaurant.currency,
        timezone: restaurant.timezone,
        active: restaurant.active?,
        created_at: restaurant.created_at,
        updated_at: restaurant.updated_at,
      }
    }
  end

  # GET /api/v1/restaurants/:id
  def show
    authorize @restaurant

    render json: {
      id: @restaurant.id,
      name: @restaurant.name,
      description: @restaurant.description,
      address: @restaurant.address,
      phone: @restaurant.phone,
      email: @restaurant.email,
      website: @restaurant.website,
      currency: @restaurant.currency,
      timezone: @restaurant.timezone,
      active: @restaurant.active?,
      created_at: @restaurant.created_at,
      updated_at: @restaurant.updated_at,
    }
  end

  # POST /api/v1/restaurants
  def create
    @restaurant = current_user.restaurants.build(restaurant_params)
    authorize @restaurant

    if @restaurant.save
      render json: restaurant_json(@restaurant), status: :created
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @restaurant.errors.full_messages.join(', ') } },
             status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/restaurants/:id
  def update
    authorize @restaurant

    if @restaurant.update(restaurant_params)
      render json: restaurant_json(@restaurant)
    else
      render json: { error: { code: 'VALIDATION_ERROR', message: @restaurant.errors.full_messages.join(', ') } },
             status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/restaurants/:id
  def destroy
    authorize @restaurant
    @restaurant.destroy
    head :no_content
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: { code: 'NOT_FOUND', message: 'Restaurant not found' } }, status: :not_found
  end

  def restaurant_params
    params.require(:restaurant).permit(:name, :description, :address, :phone, :email, :website, :currency, :timezone)
  end

  def restaurant_json(restaurant)
    {
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description,
      address: restaurant.address,
      phone: restaurant.phone,
      email: restaurant.email,
      website: restaurant.website,
      currency: restaurant.currency,
      timezone: restaurant.timezone,
      active: restaurant.active?,
      created_at: restaurant.created_at,
      updated_at: restaurant.updated_at,
    }
  end
end
