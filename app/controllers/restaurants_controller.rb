# frozen_string_literal: true

require 'stripe'

class RestaurantsController < Restaurants::BaseController
  before_action :set_restaurant, only: %i[show edit update destroy]
  before_action :set_currency, only: %i[show index]
  before_action :disable_turbo, only: [:edit]

  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_for_json?
  skip_after_action :verify_authorized, only: [:index]

  # GET /restaurants or /restaurants.json
  def index
    authorize Restaurant

    if current_user.plan
      ApplicationRecord.on_primary do
        scope = policy_scope(Restaurant)

        include_archived = ActiveModel::Type::Boolean.new.cast(params[:include_archived])
        unless include_archived
          scope = scope
            .where.not(status: Restaurant.statuses[:archived])
            .where('restaurants.archived IS NULL OR restaurants.archived = ?', false)
        end

        q = params[:q].to_s.strip
        scope = scope.where('restaurants.name ILIKE ?', "%#{q}%") if q.present?

        @q = q
        @restaurants = scope.order(:sequence)

        Rails.logger.warn(
          "[RestaurantsController#index] db_role=primary q=#{@q.inspect} restaurants_sample=" \
          "#{@restaurants.limit(10).pluck(:id, :sequence).inspect}",
        )
      end

      AnalyticsService.track_user_event(current_user, 'restaurants_viewed', {
        restaurants_count: @restaurants.count,
        has_restaurants: @restaurants.any?,
      })

      if current_user.super_admin? || current_user.plan.locations == -1
        @canAddRestaurant = true
      else
        active_count = policy_scope(Restaurant).where(archived: false, status: :active).count
        @canAddRestaurant = active_count < current_user.plan.locations
      end
    else
      redirect_to root_url
    end

    respond_to do |format|
      format.html do
        if request.headers['Turbo-Frame'] == 'restaurants_content'
          render partial: 'restaurants/index_frame_wrapper_2025',
                 locals: { restaurants: @restaurants, q: @q }
        else
          render :index_2025
        end
      end
      format.json { render 'index_minimal' }
    end
  end

  # PATCH /restaurants/bulk_update
  def bulk_update
    authorize Restaurant

    ids = Array(params[:restaurant_ids]).map(&:to_i).uniq
    operation = params[:operation].to_s
    value = params[:value]

    if ids.blank? || operation.blank?
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'Invalid bulk update' }
        format.json { render json: { success: false }, status: :unprocessable_content }
      end
      return
    end

    scope = policy_scope(Restaurant).where(id: ids)

    case operation
    when 'set_status'
      status = value.to_s
      unless Restaurant.statuses.key?(status)
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: 'Invalid status' }
          format.json { render json: { success: false }, status: :unprocessable_content }
        end
        return
      end

      if status == 'active' && !current_user_has_active_subscription?
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: 'You need an active subscription to activate a restaurant.' }
          format.json { render json: { success: false, error: 'subscription_required' }, status: :payment_required }
        end
        return
      end

      scope.find_each do |restaurant|
        authorize restaurant, :update?
        restaurant.update!(status: status)
      end
    when 'archive'
      scope.find_each do |restaurant|
        authorize restaurant, :archive?
        RestaurantArchivalService.archive_async(
          restaurant_id: restaurant.id,
          archived_by_id: current_user&.id,
          reason: params[:reason],
        )
      end
    when 'restore'
      scope.find_each do |restaurant|
        authorize restaurant, :restore?
        RestaurantArchivalService.restore_async(
          restaurant_id: restaurant.id,
          archived_by_id: current_user&.id,
          reason: params[:reason],
        )
      end
    else
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'Invalid bulk operation' }
        format.json { render json: { success: false }, status: :unprocessable_content }
      end
      return
    end

    respond_to do |format|
      format.html { redirect_to restaurants_path, notice: 'Restaurants updated' }
      format.json { render json: { success: true }, status: :ok }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: e.record.errors.full_messages.first }
      format.json { render json: { success: false }, status: :unprocessable_content }
    end
  end

  # PATCH /restaurants/reorder
  def reorder
    authorize Restaurant

    order = params[:order]
    unless order.is_a?(Array)
      render json: { success: false }, status: :unprocessable_content
      return
    end

    scope = policy_scope(Restaurant).where.not(status: Restaurant.statuses[:archived])
    permitted_ids = scope.pluck(:id)

    payload_ids = order.filter_map do |item|
      raw = if item.is_a?(ActionController::Parameters)
              item.to_unsafe_h
            elsif item.is_a?(Hash)
              item
            end
      next if raw.nil?

      raw_id = raw['id'] || raw[:id]
      next if raw_id.blank?

      id = raw_id.to_i
      next unless permitted_ids.include?(id)

      id
    end
    payload_ids = payload_ids.uniq

    remaining_ids = scope.where.not(id: payload_ids).order(:sequence, :id).pluck(:id)
    final_ids = payload_ids + remaining_ids

    Restaurant.transaction do
      final_ids.each_with_index do |id, idx|
        Restaurant.where(id: id).update_all(sequence: idx + 1)
      end
    end

    persisted_sample = ApplicationRecord.on_primary do
      policy_scope(Restaurant)
        .where.not(status: Restaurant.statuses[:archived])
        .order(:sequence, :id)
        .limit(10)
        .pluck(:id, :sequence)
    end

    Rails.logger.warn(
      "[RestaurantsController#reorder] db_role=primary payload_ids=#{payload_ids.inspect} " \
      "final_ids_first10=#{final_ids.first(10).inspect} persisted_sample=#{persisted_sample.inspect}",
    )

    render json: { success: true }, status: :ok
  end

  # GET /restaurants/1 or /restaurants/1.json
  def show
    authorize @restaurant

    return unless params[:restaurant_id] && params[:id]

    @dashboard_data = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)

    trigger_strategic_cache_warming

    AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_VIEWED, {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      restaurant_type: @restaurant.restaurant_type,
      cuisine_type: @restaurant.cuisine_type,
      has_menus: @dashboard_data[:stats][:total_menus_count].positive?,
      menus_count: @dashboard_data[:stats][:total_menus_count],
      employees_count: @dashboard_data[:stats][:staff_count],
    })
  end

  # GET /restaurants/new
  def new
    @restaurant = Restaurant.new
    @restaurant.status ||= :inactive
    authorize @restaurant

    AnalyticsService.track_user_event(current_user, 'restaurant_creation_started', {
      user_restaurants_count: current_user.restaurants.count,
      plan_name: current_user.plan&.name,
    })

    if request.headers['Turbo-Frame'] == 'new_restaurant_modal'
      render partial: 'restaurants/new_modal_form', locals: { restaurant: @restaurant }
      nil
    end
  end

  # GET /restaurants/1/edit
  def edit
    authorize @restaurant

    sync_stripe_subscription_from_checkout_session! if params[:checkout_session_id].present?

    @qrHost = request.host_with_port
    @current_employee = @restaurant.employees.find_by(user: current_user)

    begin
      owned_menu_ids = @restaurant.menus.where(archived: false).pluck(:id)
      existing_menu_ids = @restaurant.restaurant_menus.where(menu_id: owned_menu_ids).pluck(:menu_id)
      missing_menu_ids = owned_menu_ids - existing_menu_ids
      if missing_menu_ids.any?
        next_sequence = @restaurant.restaurant_menus.maximum(:sequence).to_i
        RestaurantMenu.transaction do
          missing_menu_ids.each do |menu_id|
            next_sequence += 1
            RestaurantMenu.create!(
              restaurant_id: @restaurant.id,
              menu_id: menu_id,
              sequence: next_sequence,
              status: :active,
              availability_override_enabled: false,
              availability_state: :available,
            )
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error("[RestaurantsController] Failed to sync missing restaurant menus for restaurant_id=#{@restaurant&.id}: #{e.message}")
      nil
    end

    @current_section = params[:section] || 'details'
    @onboarding_mode = ActiveModel::Type::Boolean.new.cast(params[:onboarding])
    @onboarding_next = @restaurant.onboarding_next_section

    if @current_section.to_s == 'settings'
      @stripe_connect_account = @restaurant.provider_accounts.find { |a| a.provider.to_s == 'stripe' } || @restaurant.provider_accounts.where(provider: :stripe).first
      if @stripe_connect_account&.status.to_s == 'enabled'
        @stripe_connect_receipt_details = Payments::Providers::StripeConnect
          .new(restaurant: @restaurant)
          .receipt_details_for_account(provider_account_id: @stripe_connect_account.provider_account_id)
      end
    end

    if @onboarding_next.present?
      AnalyticsService.track_user_event(current_user, 'restaurant_onboarding_step_viewed', {
        restaurant_id: @restaurant.id,
        section: @current_section,
        next_recommended_section: @onboarding_next,
        is_recommended: (@current_section == @onboarding_next),
      })
    end

    AnalyticsService.track_user_event(current_user, 'restaurant_edit_started', {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      has_employee_role: @current_employee.present?,
      employee_role: @current_employee&.role,
      section: @current_section,
    })

    return if params[:old_ui] == 'true'

    if request.headers['Turbo-Frame'] == 'restaurant_content'
      filter = @current_section.include?('menus') ? @current_section.sub('menus_', '') : 'all'
      filter = 'all' if @current_section == 'menus'

      render partial: 'restaurants/section_frame_2025',
             locals: {
               restaurant: @restaurant,
               partial_name: section_partial_name(@current_section),
               filter: filter,
             }
    else
      render :edit_2025
    end
  end

  # POST /restaurants or /restaurants.json
  def create
    @restaurant = Restaurant.new(restaurant_params)
    @restaurant.user = current_user
    @restaurant.status ||= :inactive
    authorize @restaurant

    if current_user&.plan && current_user.plan.locations != -1 && !current_user.super_admin?
      active_count = current_user.restaurants.where(archived: false, status: :active).count
      if active_count >= current_user.plan.locations
        @restaurant.errors.add(:base, 'Plan limit reached: maximum active restaurants')
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: @restaurant.errors.full_messages.to_sentence }
          format.json { render json: { errors: @restaurant.errors.full_messages }, status: :unprocessable_content }
        end
        return
      end
    end

    respond_to do |format|
      if @restaurant.save
        RestaurantProvisioningService.call(restaurant: @restaurant, user: current_user)

        AnalyticsService.track_restaurant_created(current_user, @restaurant)
        AnalyticsService.track_user_event(current_user, 'restaurant_onboarding_started', {
          restaurant_id: @restaurant.id,
          source: 'restaurants_create',
          initial_next_section: @restaurant.onboarding_next_section,
        })
        if @restaurant.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @restaurant
          @genimage.created_at = DateTime.current
          @restaurant.genimage.updated_at = DateTime.current
          @restaurant.genimage.save
        end
        format.html do
          redirect_to restaurants_path, notice: t('common.flash.created', resource: t('activerecord.models.restaurant'))
        end
        format.json { render :show, status: :created, location: @restaurant }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @restaurant.errors, status: :unprocessable_content }
      end
    end
  rescue ArgumentError => e
    @restaurant = Restaurant.new
    @restaurant.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @restaurant.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    authorize @restaurant

    respond_to do |format|
      raw_restaurant = params[:restaurant]
      status_value = params.dig(:restaurant, :status) || params[:status]

      if status_value.to_s == 'active' && !current_user_has_active_subscription?
        format.html do
          redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'details'), alert: 'You need an active subscription to activate a restaurant.',
                                                                                     status: :see_other,)
        end
        format.json { render json: { error: 'subscription_required' }, status: :payment_required }
        return
      end

      attrs = {}
      if raw_restaurant.is_a?(ActionController::Parameters)
        begin
          attrs.merge!(restaurant_params.to_h)
        rescue StandardError => e
          Rails.logger.warn("[RestaurantsController#update] restaurant_params error: #{e.message}")
        end
      end
      attrs[:status] = status_value if status_value.present?

      Rails.logger.info("[RestaurantsController#update] raw_restaurant=#{raw_restaurant.inspect} built_attrs=#{attrs.inspect}")

      @restaurant.assign_attributes(attrs)
      updated = @restaurant.changed? ? @restaurant.save : true
      Rails.logger.info("[RestaurantsController#update] save_result=#{updated} persisted_status=#{@restaurant.status}")

      if updated
        AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)

        Rails.logger.debug 'SmartMenuGeneratorJob.start'
        SmartMenuGeneratorJob.perform_sync(@restaurant.id)
        Rails.logger.debug 'SmartMenuGeneratorJob.end'

        AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_UPDATED, {
          restaurant_id: @restaurant.id,
          restaurant_name: @restaurant.name,
          changes_made: @restaurant.previous_changes.keys,
        })
        if @restaurant.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @restaurant
          @genimage.created_at = DateTime.current
          @restaurant.genimage.updated_at = DateTime.current
          @restaurant.genimage.save
        end
        format.html do
          if params[:return_to] == 'restaurant_edit'
            redirect_to edit_restaurant_path(@restaurant, section: 'details'),
                        notice: t('common.flash.updated', resource: t('activerecord.models.restaurant'))
          else
            redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                        notice: t('common.flash.updated', resource: t('activerecord.models.restaurant'))
          end
        end
        format.json do
          if request.xhr?
            onboarding_next = @restaurant.onboarding_next_section
            checklist_html = render_to_string(
              GoLiveChecklistComponent.new(restaurant: @restaurant, userplan: @userplan),
              layout: false,
            )
            render json: {
              success: true,
              message: 'Saved successfully',
              onboarding_next: onboarding_next,
              onboarding_required_text: onboarding_required_text_for(onboarding_next),
              checklist_html: checklist_html,
            }, status: :ok
          else
            render :edit, status: :ok, location: @restaurant
          end
        end
      else
        format.html do
          if params[:return_to] == 'restaurant_edit'
            redirect_to edit_restaurant_path(@restaurant, section: 'details'), alert: @restaurant.errors.full_messages.presence || 'Failed to update restaurant'
          else
            render :edit, status: :unprocessable_content
          end
        end
        format.json { render json: @restaurant.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    authorize @restaurant

    RestaurantArchivalService.archive_async(
      restaurant_id: @restaurant.id,
      archived_by_id: current_user&.id,
    )

    AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_DELETED, {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      had_menus: @restaurant.menus.any?,
      menus_count: @restaurant.menus.count,
    })

    respond_to do |format|
      format.html do
        redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant'))
      end
      format.json { head :no_content }
    end
  end

  private

  def sync_stripe_subscription_from_checkout_session!
    ensure_stripe_api_key_for_restaurants!
    return if Stripe.api_key.to_s.strip.blank?

    session_id = params[:checkout_session_id].to_s
    session = Stripe::Checkout::Session.retrieve({ id: session_id, expand: ['subscription'] })

    stripe_customer_id = session.customer.to_s
    subscription_obj = session.subscription
    stripe_subscription_id = if subscription_obj.respond_to?(:id)
                               subscription_obj.id.to_s
                             else
                               session.subscription.to_s
                             end

    return if stripe_customer_id.blank? || stripe_subscription_id.blank?

    subscription = if subscription_obj.respond_to?(:status)
                     subscription_obj
                   else
                     Stripe::Subscription.retrieve({ id: stripe_subscription_id, expand: ['default_payment_method'] })
                   end

    status = case subscription.status.to_s
             when 'active'
               :active
             when 'trialing'
               :trialing
             when 'past_due', 'unpaid'
               :past_due
             when 'canceled', 'incomplete_expired'
               :canceled
             else
               :inactive
             end

    has_payment_method = subscription.respond_to?(:default_payment_method) && subscription.default_payment_method.present?
    has_payment_method ||= subscription.respond_to?(:default_source) && subscription.default_source.present?
    has_payment_method ||= session.payment_status.to_s == 'paid'

    rs = @restaurant.restaurant_subscription || @restaurant.build_restaurant_subscription(status: :inactive)
    rs.update!(
      status: status,
      stripe_customer_id: stripe_customer_id,
      stripe_subscription_id: stripe_subscription_id,
      payment_method_on_file: has_payment_method,
      trial_ends_at: begin
        t = subscription.respond_to?(:trial_end) ? subscription.trial_end : nil
        t.present? ? Time.zone.at(t.to_i) : rs.trial_ends_at
      rescue StandardError => e
        Rails.logger.warn("[RestaurantsController] Failed to convert trial_ends_at timestamp: #{e.message}")
        rs.trial_ends_at
      end,
      current_period_end: begin
        t = subscription.respond_to?(:current_period_end) ? subscription.current_period_end : nil
        t.present? ? Time.zone.at(t.to_i) : rs.current_period_end
      rescue StandardError => e
        Rails.logger.warn("[RestaurantsController] Failed to convert current_period_end timestamp: #{e.message}")
        rs.current_period_end
      end,
    )
  rescue StandardError => e
    Rails.logger.warn("[StripeCheckoutSync] Failed to sync checkout_session_id=#{params[:checkout_session_id]} restaurant_id=#{@restaurant&.id}: #{e.class}: #{e.message}")
  end

  def ensure_stripe_api_key_for_restaurants!
    return if Stripe.api_key.present?

    env_key = ENV['STRIPE_SECRET_KEY'].presence

    credentials_key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError => e
      Rails.logger.warn("[RestaurantsController] Failed to read credentials stripe_secret_key: #{e.message}")
      nil
    end

    if credentials_key.blank?
      credentials_key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError => e
        Rails.logger.warn("[RestaurantsController] Failed to dig credentials for stripe key: #{e.message}")
        nil
      end
    end

    key = if Rails.env.production?
            env_key || credentials_key
          else
            credentials_key.presence || env_key
          end

    Stripe.api_key = key if key.present?
  end

  def restaurant_params
    permitted = params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country,
                                                   :image, :remove_image, :status, :sequence, :capacity, :displayImages, :displayImagesInPopup, :allowOrdering, :allow_alcohol, :inventoryTracking, :currency, :genid, :latitude, :longitude, :imagecontext, :image_style_profile, :wifissid, :wifiEncryptionType, :wifiPassword, :wifiHidden, :spotifyuserid, establishment_types: [],)

    if permitted[:status].present? && permitted[:status].is_a?(String)
      permitted[:status] = permitted[:status].to_i
    end

    permitted
  end
end
