# frozen_string_literal: true

class Payments::SquareConnectController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  # GET /restaurants/:restaurant_id/payments/square/connect
  def connect
    authorize @restaurant, :update?

    unless SquareConfig.configured?
      redirect_back_or_to edit_restaurant_path(@restaurant, section: 'settings'),
                          alert: 'Square is not configured. Set SQUARE_*_CLIENT_ID and SQUARE_*_CLIENT_SECRET environment variables.'
      return
    end

    state = SecureRandom.urlsafe_base64(32)
    session[:square_oauth_state] = state

    url = square_connect.authorize_url(
      redirect_uri: restaurant_payments_square_callback_url(@restaurant),
      state: state,
    )

    redirect_to url, allow_other_host: true
  end

  # GET /restaurants/:restaurant_id/payments/square/callback
  def callback
    authorize @restaurant, :update?

    if params[:error].present?
      redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                  alert: "Square authorization failed: #{params[:error_description] || params[:error]}"
      return
    end

    if params[:state] != session.delete(:square_oauth_state)
      redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                  alert: 'Invalid OAuth state. Please try connecting again.'
      return
    end

    result = square_connect.exchange_code!(
      code: params[:code],
      redirect_uri: restaurant_payments_square_callback_url(@restaurant),
    )

    if result[:locations].length > 1 && @restaurant.square_location_id.blank?
      redirect_to restaurant_payments_square_locations_path(@restaurant),
                  notice: 'Square connected! Please select a location.'
    else
      redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                  notice: 'Square connected successfully.'
    end
  rescue Payments::Providers::SquareHttpClient::SquareApiError => e
    Rails.logger.error("[SquareConnect] callback failed restaurant_id=#{@restaurant.id}: #{e.message}")
    redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                alert: "Square connection failed: #{e.message}"
  end

  # DELETE /restaurants/:restaurant_id/payments/square/disconnect
  def disconnect
    authorize @restaurant, :update?

    square_connect.revoke!

    redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                notice: 'Square disconnected.'
  end

  # GET /restaurants/:restaurant_id/payments/square/locations
  def locations
    authorize @restaurant, :update?

    account = ProviderAccount.find_by(restaurant: @restaurant, provider: :square)
    unless account&.access_token.present?
      redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                  alert: 'Square is not connected.'
      return
    end

    @locations = square_connect.fetch_locations
    @selected_location_id = @restaurant.square_location_id
  end

  # PATCH /restaurants/:restaurant_id/payments/square/location
  def update_location
    authorize @restaurant, :update?

    @restaurant.update!(square_location_id: params[:location_id])

    redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                notice: 'Square location updated.'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def square_connect
    @square_connect ||= Payments::Providers::SquareConnect.new(restaurant: @restaurant)
  end
end
