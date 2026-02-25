module Admin
  class DiscoveredRestaurantsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_discovered_restaurant, only: %i[show update approve reject deep_dive_website deep_dive_status scrape_web_menus web_menu_scrape_status place_details refresh_place_details resync_to_restaurant kill_enrichment]

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

    def show
      auto_enrich_if_needed
    end

    # POST /admin/discovered_restaurants
    def create
      website_url = params.dig(:discovered_restaurant, :website_url).to_s.strip
      name = params.dig(:discovered_restaurant, :name).to_s.strip
      city_name = params.dig(:discovered_restaurant, :city_name).to_s.strip

      if website_url.blank?
        redirect_to admin_discovered_restaurants_path, alert: 'Website URL is required', status: :see_other
        return
      end

      # Normalize URL
      website_url = "https://#{website_url}" unless website_url.match?(%r{\Ahttps?://}i)

      # Auto-fill name from domain if not provided
      if name.blank?
        uri = begin
          URI.parse(website_url)
        rescue StandardError
          nil
        end
        name = uri&.host&.delete_prefix('www.')&.split('.')&.first&.titleize || 'Unknown'
      end

      city_name = 'Manual Entry' if city_name.blank?

      dr = DiscoveredRestaurant.new(
        name: name,
        website_url: website_url,
        city_name: city_name,
        google_place_id: "manual_#{SecureRandom.hex(8)}",
        status: :pending,
        discovered_at: Time.current,
        metadata: { 'source' => 'manual', 'created_by' => current_user&.id },
      )

      if dr.save
        redirect_to admin_discovered_restaurant_path(dr), notice: "#{dr.name} added — run Deep Dive or Web Menu Scrape to populate details", status: :see_other
      else
        redirect_to admin_discovered_restaurants_path, alert: "Could not create: #{dr.errors.full_messages.join(', ')}", status: :see_other
      end
    end

    def update
      @discovered_restaurant.assign_attributes(discovered_restaurant_params)

      if @discovered_restaurant.currency.blank? && @discovered_restaurant.country_code.present?
        inferred = CountryCurrencyInference.new.infer(@discovered_restaurant.country_code)
        @discovered_restaurant.currency = inferred if inferred.present?
      end

      changed = @discovered_restaurant.changed
      trackable = %w[name description establishment_types preferred_phone preferred_email address1 city state postcode country_code currency image_context image_style_profile]
      manual_fields = (changed & trackable).reject do |f|
        old_val = @discovered_restaurant.attribute_was(f)
        new_val = @discovered_restaurant.read_attribute(f)
        old_val.blank? && new_val.blank?
      end
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
      when 'publish_preview'
        scope.where.not(restaurant_id: nil).includes(:restaurant).find_each do |dr|
          next unless dr.restaurant

          dr.restaurant.update!(
            preview_enabled: true,
            preview_published_at: dr.restaurant.preview_published_at || Time.current,
          )

          # Create smartmenus for active menus that don't have one
          dr.restaurant.menus.where(status: 'active').find_each do |menu|
            next if Smartmenu.exists?(restaurant_id: dr.restaurant.id, menu_id: menu.id, tablesetting_id: nil)

            Smartmenu.create!(restaurant: dr.restaurant, menu: menu, slug: SecureRandom.uuid)
          end
        end
      when 'unpublish_preview'
        scope.where.not(restaurant_id: nil).includes(:restaurant).find_each do |dr|
          next unless dr.restaurant

          dr.restaurant.update!(preview_enabled: false, preview_indexable: false)
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
      elsif @discovered_restaurant.restaurant.present?
        @discovered_restaurant.restaurant.update!(preview_enabled: true, preview_published_at: Time.current)
      end

      redirect_back_or_to(admin_discovered_restaurants_path, notice: 'Approved', status: :see_other)
    end

    def reject
      @discovered_restaurant.update!(status: :rejected)
      redirect_back_or_to(admin_discovered_restaurants_path, notice: 'Rejected', status: :see_other)
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

    def scrape_web_menus
      if @discovered_restaurant.website_url.blank?
        redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: 'No website URL available', status: :see_other)
        return
      end

      metadata = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
      metadata['web_menu_scrape'] = (metadata['web_menu_scrape'].is_a?(Hash) ? metadata['web_menu_scrape'] : {}).merge(
        'status' => 'queued',
        'queued_at' => Time.current.iso8601,
        'error' => nil,
      )
      @discovered_restaurant.update!(metadata: metadata)

      DiscoveredRestaurantWebMenuScrapeJob.perform_later(
        discovered_restaurant_id: @discovered_restaurant.id,
        triggered_by_user_id: current_user.id,
      )

      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: 'Web menu scrape queued', status: :see_other)
    end

    def web_menu_scrape_status
      scrape = @discovered_restaurant.metadata.is_a?(Hash) ? (@discovered_restaurant.metadata['web_menu_scrape'] || {}) : {}

      render json: {
        status: scrape['status'].to_s.presence || 'unknown',
        html_pages_found: scrape['html_pages_found'],
        pdf_urls_found: scrape['pdf_urls_found'],
        pages_scraped: scrape['pages_scraped'],
        ocr_menu_import_id: scrape['ocr_menu_import_id'],
        sections_count: scrape['sections_count'],
        items_count: scrape['items_count'],
        message: scrape['message'],
        error: scrape['error'],
        updated_at: scrape['updated_at'],
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
          'opening_hours' => details[:opening_hours],
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

    def approved_imports
      scope = DiscoveredRestaurant
        .where(status: :approved)
        .includes(:restaurant, menu_sources: { latest_file_attachment: :blob })
        .order(updated_at: :desc)

      city = params[:city].to_s.strip
      scope = scope.where('city_name ILIKE ?', "%#{city}%") if city.present?

      @city = city
      @approved = scope.limit(200)
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

    def kill_enrichment
      killed = []
      metadata = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}

      # Reset web_menu_scrape status if active
      scrape = metadata['web_menu_scrape']
      if scrape.is_a?(Hash) && %w[queued scraping processing].include?(scrape['status'])
        scrape['status'] = 'killed'
        scrape['killed_at'] = Time.current.iso8601
        metadata['web_menu_scrape'] = scrape
        killed << 'Web menu scrape'
      end

      # Reset website_deep_dive status if active
      deep_dive = metadata['website_deep_dive']
      if deep_dive.is_a?(Hash) && %w[queued processing scraping].include?(deep_dive['status'])
        deep_dive['status'] = 'killed'
        deep_dive['killed_at'] = Time.current.iso8601
        metadata['website_deep_dive'] = deep_dive
        killed << 'Website deep dive'
      end

      @discovered_restaurant.update!(metadata: metadata)

      # Remove matching jobs from Sidekiq queues
      removed = remove_sidekiq_jobs_for(@discovered_restaurant.id)
      killed << "#{removed} Sidekiq job(s) removed" if removed.positive?

      msg = killed.any? ? "Killed: #{killed.join(', ')}" : 'No active enrichment processes found'
      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), notice: msg, status: :see_other)
    rescue StandardError => e
      redirect_back_or_to(admin_discovered_restaurant_path(@discovered_restaurant), alert: "Kill failed: #{e.message}", status: :see_other)
    end

    private

    def set_discovered_restaurant
      @discovered_restaurant = DiscoveredRestaurant.find(params[:id])
    end

    # Auto-trigger enrichment jobs on first view if they have never been run
    def auto_enrich_if_needed
      meta = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
      place_details = meta['place_details'].is_a?(Hash) ? meta['place_details'] : {}
      deep_dive     = meta['website_deep_dive'].is_a?(Hash) ? meta['website_deep_dive'] : {}
      web_scrape    = meta['web_menu_scrape'].is_a?(Hash) ? meta['web_menu_scrape'] : {}

      queued_any = false

      # 1. Google Places lookup — never fetched and has a real google_place_id
      gpi = @discovered_restaurant.google_place_id.to_s.strip
      if place_details['fetched_at'].blank? && gpi.present? && !gpi.start_with?('manual_')
        DiscoveredRestaurantRefreshPlaceDetailsJob.perform_later(
          discovered_restaurant_id: @discovered_restaurant.id,
          triggered_by_user_id: current_user&.id,
        )
        queued_any = true
      end

      # 2. Website deep dive — never run and has a website URL
      if deep_dive['status'].blank? && @discovered_restaurant.website_url.present?
        deep_dive_meta = deep_dive.merge(
          'status' => 'queued',
          'queued_at' => Time.current.iso8601,
          'auto_triggered' => true,
        )
        meta['website_deep_dive'] = deep_dive_meta

        DiscoveredRestaurantWebsiteDeepDiveJob.perform_later(
          discovered_restaurant_id: @discovered_restaurant.id,
          triggered_by_user_id: current_user&.id,
        )
        queued_any = true
      end

      # 3. Web menu scrape — never run and has a website URL
      if web_scrape['status'].blank? && @discovered_restaurant.website_url.present?
        web_scrape_meta = web_scrape.merge(
          'status' => 'queued',
          'queued_at' => Time.current.iso8601,
          'auto_triggered' => true,
        )
        meta['web_menu_scrape'] = web_scrape_meta

        DiscoveredRestaurantWebMenuScrapeJob.perform_later(
          discovered_restaurant_id: @discovered_restaurant.id,
          triggered_by_user_id: current_user&.id,
        )
        queued_any = true
      end

      if queued_any
        @discovered_restaurant.update!(metadata: meta)
        @discovered_restaurant.reload
      end
    rescue StandardError => e
      Rails.logger.warn "[AutoEnrich] Failed for DR##{@discovered_restaurant&.id}: #{e.message}"
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

    # Remove queued/scheduled/retry Sidekiq jobs that target this discovered restaurant
    DR_ENRICHMENT_JOB_CLASSES = %w[
      DiscoveredRestaurantWebMenuScrapeJob
      DiscoveredRestaurantWebsiteDeepDiveJob
      DiscoveredRestaurantRefreshPlaceDetailsJob
    ].freeze

    def remove_sidekiq_jobs_for(dr_id)
      require 'sidekiq/api'
      removed = 0
      dr_id_s = dr_id.to_s

      # Scan default queue
      Sidekiq::Queue.new('default').each do |job|
        if dr_enrichment_job_for?(job, dr_id_s)
          job.delete
          removed += 1
        end
      end

      # Scan scheduled set
      Sidekiq::ScheduledSet.new.each do |job|
        if dr_enrichment_job_for?(job, dr_id_s)
          job.delete
          removed += 1
        end
      end

      # Scan retry set
      Sidekiq::RetrySet.new.each do |job|
        if dr_enrichment_job_for?(job, dr_id_s)
          job.delete
          removed += 1
        end
      end

      removed
    end

    def dr_enrichment_job_for?(job, dr_id_s)
      wrapped = job['wrapped'] || job.item['wrapped']
      return false unless DR_ENRICHMENT_JOB_CLASSES.include?(wrapped.to_s)

      args = job['args'] || job.item['args'] || []
      aj_payload = args.first
      return false unless aj_payload.is_a?(Hash)

      aj_args = aj_payload['arguments'] || []
      aj_args.any? { |a| a.is_a?(Hash) && a['discovered_restaurant_id'].to_s == dr_id_s }
    end
  end
end
