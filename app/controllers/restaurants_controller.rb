require 'rspotify'

class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[ show edit update destroy ]
  before_action :set_currency, only: %i[ show index ]
  before_action :disable_turbo, only: [:edit]

  require 'rspotify'

  def spotify_auth
    if params[:restaurant_id]
      session[:spotify_restaurant_id] = params[:restaurant_id]
    end
    scopes = %w[
      user-read-email
      user-read-private
      user-library-read
      playlist-read-private
      user-read-recently-played
      app-remote-control
      streaming
    ].join(' ')
    spotify_auth_url = "https://accounts.spotify.com/authorize?client_id="+Rails.application.credentials.spotify_key+"&response_type=code&redirect_uri=#{ENV['SPOTIFY_REDIRECT_URI']}&scope=#{scopes}"
    redirect_to spotify_auth_url, allow_other_host: true
  end

  def spotify_callback
    if params[:code]
      auth_response = RestClient.post("https://accounts.spotify.com/api/token", {
        grant_type: "authorization_code",
        code: params[:code],
        redirect_uri: ENV['SPOTIFY_REDIRECT_URI'],
        client_id: Rails.application.credentials.spotify_key,
        client_secret: Rails.application.credentials.spotify_secret
      })
      auth_data = JSON.parse(auth_response.body)
      puts auth_data
      spotify_user = RSpotify::User.new(auth_data)

      session[:spotify_user] = {
        id: spotify_user.id,
        display_name: spotify_user.display_name,
        email: spotify_user.email,
        token: auth_data["access_token"],
        refresh_token: auth_data["refresh_token"],
        expires_at: Time.now.to_i + auth_data["expires_in"]
      }
      if session[:spotify_restaurant_id]
        # Use fetch with cache
        @restaurant = Restaurant.fetch(session[:spotify_restaurant_id])
        @restaurant.spotifyaccesstoken = auth_data["access_token"]
        @restaurant.spotifyrefreshtoken = auth_data["refresh_token"]
        @restaurant.save
        
        # Expire the cache for this restaurant
        @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)
        
        puts @restaurant.name
        puts @restaurant.id
        puts edit_restaurant_path(@restaurant)
        redirect_to root_url
      end
    else
      render json: { error: "Authorization failed" }, status: 401
    end
  end

  def logout
    session.delete(:spotify_user)
    render json: { message: "Logged out" }
  end

  # GET /restaurants or /restaurants.json
  def index
    if current_user && current_user.plan
        # Use fetch_by_user_id which is automatically provided by identity_cache
        @restaurants = Restaurant.fetch_by_user_id(current_user.id).reject { |r| r.archived? }
        
        Analytics.track(
            user_id: current_user.id,
            event: 'restaurants.index'
        )
        
        if @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
           @canAddRestaurant = true
        else
           @canAddRestaurant = false
        end
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/1 or /restaurants/1.json
  def show
    if current_user
        if params[:restaurant_id] && params[:id]
            # Use fetch to get the restaurant with caching
            @restaurant = Restaurant.fetch(params[:id])
            
            # Preload associations that will be used in the view
            @restaurant.fetch_menus if @restaurant.respond_to?(:fetch_menus)
            @restaurant.fetch_tablesettings if @restaurant.respond_to?(:fetch_tablesettings)
            
            Analytics.track(
                user_id: current_user.id,
                event: 'restaurants.show',
                properties: {
                  restaurant_id: params[:id]
                }
            )
        end
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/new
  def new
    if current_user
        @restaurant = Restaurant.new
            Analytics.track(
                user_id: current_user.id,
                event: 'restaurants.new'
            )
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/1/edit
  def edit
    if current_user
        @qrHost = request.host_with_port

        Analytics.track(
            user_id: current_user.id,
            event: 'restaurants.edit',
            properties: {
                  restaurant_id: params[:id]
            }
        )
    else
        redirect_to root_url
    end
  end

  # POST /restaurants or /restaurants.json
  def create
    if current_user
        @restaurant = Restaurant.new(restaurant_params)
        respond_to do |format|
          if @restaurant.save
            Analytics.track(
                user_id: current_user.id,
                event: 'restaurants.save',
                properties: {
                  restaurant_id: params[:id]
                }
            )
            if( @restaurant.genimage == nil)
                @genimage = Genimage.new
                @genimage.restaurant = @restaurant
                @genimage.created_at = DateTime.current
                @restaurant.genimage.updated_at = DateTime.current
                @restaurant.genimage.save
            end
            format.html { redirect_to restaurants_path, notice: t('common.flash.created', resource: t('activerecord.models.restaurant')) }
            format.json { render :show, status: :created, location: @restaurant }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @restaurant.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    if current_user
        respond_to do |format|
          if @restaurant.update(restaurant_params)
            # Expire the cache for this restaurant
            @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)
            
            puts 'SmartMenuSyncJob.start'
            SmartMenuSyncJob.perform_sync(@restaurant.id)
            puts 'SmartMenuSyncJob.end'

#             puts 'SpotifySyncJob.start'
#             SpotifySyncJob.perform_sync(@restaurant.id)
#             puts 'SpotifySyncJob.end'

            Analytics.track(
                user_id: current_user.id,
                event: 'restaurants.update',
                properties: {
                  restaurant_id: params[:id]
                }
            )
            if( @restaurant.genimage == nil)
                @genimage = Genimage.new
                @genimage.restaurant = @restaurant
                @genimage.created_at = DateTime.current
                @restaurant.genimage.updated_at = DateTime.current
                @restaurant.genimage.save
            end
            format.html { redirect_to edit_restaurant_path(@restaurant), notice: t('common.flash.updated', resource: t('activerecord.models.restaurant')) }
            format.json { render :edit, status: :ok, location: @restaurant }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @restaurant.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    if current_user
      # Get the user_id before destroying for cache invalidation
      user_id = @restaurant.user_id
      
      @restaurant.update(archived: true)
      
      # Expire the user's restaurant list cache
      Restaurant.expire_user_id(user_id) if Restaurant.respond_to?(:expire_user_id)
      
      Analytics.track(
        user_id: current_user.id,
        event: 'restaurants.destroy',
        properties: {
          restaurant_id: params[:id]
        }
      )
      
      respond_to do |format|
        format.html { redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant')) }
        format.json { head :no_content }
      end
    else
      redirect_to root_url
    end
  end

  private

    def disable_turbo
      @disable_turbo = true
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_restaurant
      begin
        id_param = params[:restaurant_id] || params[:id]

        if current_user
          # Always scope by current_user to guarantee ownership and avoid IdentityCache read-only records
          @restaurant = current_user.restaurants.find(id_param)
        else
          @restaurant = Restaurant.find(id_param)
        end

        # Check if user can add more menus
        @canAddMenu = false
        if @restaurant && current_user
          # Use cached count if available, otherwise fallback to query
          @menuCount = if @restaurant.respond_to?(:fetch_menus)
            @restaurant.fetch_menus.count { |m| m.status == 'active' && !m.archived? }
          else
            Menu.where(restaurant: @restaurant, status: 'active', archived: false).count
          end

          @canAddMenu = @menuCount < current_user.plan.menusperlocation || current_user.plan.menusperlocation == -1
        end

      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn "Restaurant not found for id=#{id_param} or does not belong to current_user"
        redirect_to root_url
      end
    end

    def set_currency
      if params[:id]
        # Use fetch with cache for currency lookup
        @restaurant = Restaurant.fetch(params[:id])
        if @restaurant&.currency.present?
          @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
        else
          @restaurantCurrency = ISO4217::Currency.from_code('USD')
        end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def restaurant_params
      params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country, :image, :remove_image, :status, :sequence, :capacity, :user_id, :displayImages, :displayImagesInPopup, :allowOrdering, :inventoryTracking, :currency, :genid, :latitude, :longitude, :imagecontext, :image_style_profile, :wifissid, :wifiEncryptionType, :wifiPassword, :wifiHidden, :spotifyuserid )
    end
end
