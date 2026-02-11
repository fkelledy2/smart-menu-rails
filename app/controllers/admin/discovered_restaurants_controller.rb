module Admin
  class DiscoveredRestaurantsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_discovered_restaurant, only: %i[show update approve reject blacklist publish_preview deep_dive_website deep_dive_status place_details refresh_place_details resync_to_restaurant]

    def index
      base_scope = DiscoveredRestaurant.all

      status = params[:status].to_s.presence
      if status.present? && DiscoveredRestaurant.statuses.key?(status)
        base_scope = base_scope.where(status: DiscoveredRestaurant.statuses[status])
      end

      city = params[:city].to_s.strip
      base_scope = base_scope.where('city_name ILIKE ?', "%#{city}%") if city.present?

      sort = params[:sort].to_s.presence || 'discovered_at'
      direction = params[:direction].to_s.downcase == 'asc' ? 'asc' : 'desc'

      allowed_sorts = {
        'discovered_at' => 'COALESCE(discovered_at, created_at)',
        'city_name' => 'city_name',
        'name' => 'name',
        'status' => 'status',
        'menus_count' => 'menus_count',
      }

      page = params[:page].to_i
      page = 1 if page < 1
      per_page = params[:per_page].to_i
      per_page = 50 if per_page <= 0
      per_page = 200 if per_page > 200

      @status = status
      @city = city
      @sort = allowed_sorts.key?(sort) ? sort : 'discovered_at'
      @direction = direction
      @page = page
      @per_page = per_page

      @total_count = base_scope.count
      @total_pages = (@total_count.to_f / per_page).ceil

      if @sort == 'menus_count'
        pdf_type = MenuSource.source_types[:pdf]
        count_expr = "COUNT(CASE WHEN menu_sources.source_type = #{pdf_type} THEN 1 END)"

        scope = base_scope
          .left_joins(:menu_sources)
          .select(
            'discovered_restaurants.*',
            "#{count_expr} AS menus_count",
          )
          .group('discovered_restaurants.id')
          .order(Arel.sql("#{count_expr} #{direction}"), id: :desc)
          .includes(menu_sources: { latest_file_attachment: :blob })
      else
        order_expr = allowed_sorts[@sort] || allowed_sorts['discovered_at']
        scope = base_scope
          .includes(menu_sources: { latest_file_attachment: :blob })
          .order(Arel.sql("#{order_expr} #{direction}"), id: :desc)
      end

      @discovered_restaurants = scope.offset((page - 1) * per_page).limit(per_page)
    end

    def show; end

    def update
      @discovered_restaurant.assign_attributes(discovered_restaurant_params)

      if @discovered_restaurant.currency.blank? && @discovered_restaurant.country_code.present?
        inferred = CountryCurrencyInference.new.infer(@discovered_restaurant.country_code)
        @discovered_restaurant.currency = inferred if inferred.present?
      end

      changed = @discovered_restaurant.changed
      trackable = %w[name description establishment_types preferred_phone preferred_email address1 city state postcode country_code currency image_context image_style_profile]
      manual_fields = changed & trackable
      if manual_fields.any?
        meta = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
        fs = meta['field_sources'].is_a?(Hash) ? meta['field_sources'] : {}
        now = Time.current.iso8601
        manual_fields.each { |f| fs[f] = { 'source' => 'manual', 'updated_at' => now } }
        meta['field_sources'] = fs
        @discovered_restaurant.metadata = meta
      end

      @discovered_restaurant.save!

      if @discovered_restaurant.restaurant.present?
        DiscoveredRestaurantRestaurantSyncService.new(
          discovered_restaurant: @discovered_restaurant,
          restaurant: @discovered_restaurant.restaurant,
        ).sync!
      end

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Saved', status: :see_other)
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: e.record.errors.full_messages.first, status: :see_other)
    end

    def bulk_update
      ids = Array(params[:discovered_restaurant_ids]).map(&:to_i).uniq
      operation = params[:operation].to_s
      value = params[:value].to_s

      if ids.blank? || operation.blank? || value.blank?
        redirect_to admin_discovered_restaurants_path, alert: 'Invalid bulk update', status: :see_other
        return
      end

      scope = DiscoveredRestaurant.where(id: ids)

      case operation
      when 'set_status'
        unless DiscoveredRestaurant.statuses.key?(value)
          redirect_to admin_discovered_restaurants_path, alert: 'Invalid status', status: :see_other
          return
        end

        status_value = value

        scope.find_each do |dr|
          dr.update!(status: status_value)

          if status_value == 'approved' && dr.restaurant_id.blank?
            ProvisionUnclaimedRestaurantJob.perform_later(
              discovered_restaurant_id: dr.id,
              provisioning_user_id: current_user.id,
            )
          end
        end
      else
        redirect_to admin_discovered_restaurants_path, alert: 'Invalid bulk operation', status: :see_other
        return
      end

      redirect_to admin_discovered_restaurants_path, notice: 'Discovery queue updated', status: :see_other
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_discovered_restaurants_path, alert: e.record.errors.full_messages.first, status: :see_other
    end

    def approve
      place_details = @discovered_restaurant.metadata.is_a?(Hash) ? (@discovered_restaurant.metadata['place_details'] || {}) : {}
      google_types = Array(place_details['types'])
      google_phone = place_details['international_phone_number'].to_s.strip

      if google_types.any?
        inferred = EstablishmentTypeInference.new.infer_from_google_places_types(google_types)
        if inferred.present?
          @discovered_restaurant.establishment_types = (Array(@discovered_restaurant.establishment_types) + Array(inferred)).uniq
        end
      end

      if @discovered_restaurant.preferred_phone.blank? && google_phone.present?
        @discovered_restaurant.preferred_phone = google_phone
      end

      @discovered_restaurant.update!(status: :approved)

      if @discovered_restaurant.restaurant_id.blank?
        ProvisionUnclaimedRestaurantJob.perform_later(
          discovered_restaurant_id: @discovered_restaurant.id,
          provisioning_user_id: current_user.id,
        )
      end

      redirect_back_or_to(admin_discovered_restaurants_path, notice: 'Approved', status: :see_other)
    end

    def reject
      @discovered_restaurant.update!(status: :rejected)
      redirect_back_or_to(admin_discovered_restaurants_path, notice: 'Rejected', status: :see_other)
    end

    def blacklist
      @discovered_restaurant.update!(status: :blacklisted)
      redirect_back_or_to(admin_discovered_restaurants_path, notice: 'Blacklisted', status: :see_other)
    end

    def publish_preview
      restaurant = @discovered_restaurant.restaurant
      if restaurant
        restaurant.update!(preview_enabled: true, preview_published_at: Time.current)
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Preview published', status: :see_other)
        return
      end

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'No restaurant provisioned yet', status: :see_other)
    end

    def deep_dive_website
      if @discovered_restaurant.website_url.blank?
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'No website URL available', status: :see_other)
        return
      end

      metadata = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
      metadata['website_deep_dive'] = (metadata['website_deep_dive'].is_a?(Hash) ? metadata['website_deep_dive'] : {}).merge(
        'status' => 'queued',
        'queued_at' => Time.current.iso8601,
        'error' => nil,
      )
      @discovered_restaurant.update!(metadata: metadata)

      DiscoveredRestaurantWebsiteDeepDiveJob.perform_later(
        discovered_restaurant_id: @discovered_restaurant.id,
        triggered_by_user_id: current_user.id,
      )

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Website deep dive queued', status: :see_other)
    end

    def deep_dive_status
      deep_dive = @discovered_restaurant.metadata.is_a?(Hash) ? (@discovered_restaurant.metadata['website_deep_dive'] || {}) : {}

      render json: {
        status: deep_dive['status'].to_s.presence || 'unknown',
        extracted_at: deep_dive['extracted_at'],
        error: deep_dive['error'],
      }
    end

    def place_details
      place_details = @discovered_restaurant.metadata.is_a?(Hash) ? (@discovered_restaurant.metadata['place_details'] || {}) : {}
      render json: {
        google_place_id: @discovered_restaurant.google_place_id,
        place_details: place_details,
      }
    end

    def refresh_place_details
      place_id = @discovered_restaurant.google_place_id.to_s.strip
      if place_id.blank?
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'No Google Place ID', status: :see_other)
        return
      end

      key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil) || ENV.fetch('GOOGLE_MAPS_BROWSER_API_KEY', nil)
      key ||= begin; Rails.application.credentials.google_maps_api_key; rescue StandardError; nil; end

      if key.blank?
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'Google Maps API key not configured', status: :see_other)
        return
      end

      details = GooglePlaces::PlaceDetails.new(api_key: key).fetch!(place_id)
      if details.is_a?(Hash)
        fetched = {
          'formatted_address' => details[:formatted_address],
          'international_phone_number' => details[:international_phone_number],
          'google_url' => details[:google_url],
          'types' => Array(details[:types]),
          'address_components' => Array(details[:address_components]),
          'location' => details[:location],
          'fetched_at' => Time.current.iso8601,
        }.compact

        metadata = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
        metadata['place_details'] = (metadata['place_details'].is_a?(Hash) ? metadata['place_details'] : {}).merge(fetched)
        @discovered_restaurant.update!(metadata: metadata)
      end

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Google Places data refreshed', status: :see_other)
    rescue StandardError => e
      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: "Google Places refresh failed: #{e.message}", status: :see_other)
    end

    def resync_to_restaurant
      restaurant = @discovered_restaurant.restaurant
      unless restaurant
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'No linked restaurant', status: :see_other)
        return
      end

      DiscoveredRestaurantRestaurantSyncService.new(
        discovered_restaurant: @discovered_restaurant,
        restaurant: restaurant,
      ).sync!

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Synced to restaurant', status: :see_other)
    rescue StandardError => e
      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: "Sync failed: #{e.message}", status: :see_other)
    end

    private

    def set_discovered_restaurant
      @discovered_restaurant = DiscoveredRestaurant.find(params[:id])
    end

    def discovered_restaurant_params
      params.require(:discovered_restaurant).permit(
        :name,
        :website_url,
        :description,
        :address1,
        :address2,
        :city,
        :state,
        :postcode,
        :country_code,
        :currency,
        :preferred_phone,
        :preferred_email,
        :image_context,
        :image_style_profile,
        establishment_types: [],
      )
    end

    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
    end
  end
end
