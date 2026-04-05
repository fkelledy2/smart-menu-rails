# frozen_string_literal: true

# POST /restaurants/:restaurant_id/ordrs/:ordr_id/guest_rating
# Allows a guest (unauthenticated) to submit a 1–5 star rating after checkout.
# A `rating.low` domain event is automatically emitted when stars <= 2,
# which triggers the Reputation & Feedback Agent workflow.
class GuestRatingsController < ApplicationController
  include CsrfSafeGuestActions

  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :set_restaurant
  before_action :set_ordr

  after_action :verify_authorized

  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/guest_rating
  def create
    authorize GuestRating.new(restaurant: @restaurant, ordr: @ordr), :create?

    if GuestRating.exists?(ordr_id: @ordr.id, source: 'in_app')
      render json: { ok: false, error: 'Rating already submitted for this order.' }, status: :unprocessable_content
      return
    end

    @rating = GuestRating.new(
      ordr: @ordr,
      restaurant: @restaurant,
      stars: rating_params[:stars].to_i,
      comment: rating_params[:comment].to_s.strip,
      source: 'in_app',
    )

    if @rating.save
      render json: { ok: true, stars: @rating.stars }, status: :created
    else
      render json: { ok: false, errors: @rating.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, error: 'Restaurant not found.' }, status: :not_found
  end

  def set_ordr
    @ordr = Ordr.where(restaurant_id: @restaurant.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, error: 'Order not found.' }, status: :not_found
  end

  def rating_params
    params.require(:guest_rating).permit(:stars, :comment)
  end
end
