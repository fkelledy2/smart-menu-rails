# frozen_string_literal: true

class AnalyticsService
  include Singleton

  # Onboarding Events
  ONBOARDING_STARTED = 'onboarding_started'
  ONBOARDING_STEP_COMPLETED = 'onboarding_step_completed'
  ONBOARDING_STEP_FAILED = 'onboarding_step_failed'
  ONBOARDING_COMPLETED = 'onboarding_completed'
  ONBOARDING_ABANDONED = 'onboarding_abandoned'

  # User Events
  USER_SIGNED_UP = 'user_signed_up'
  USER_SIGNED_IN = 'user_signed_in'
  USER_SIGNED_OUT = 'user_signed_out'
  USER_PROFILE_UPDATED = 'user_profile_updated'

  # Restaurant Events
  RESTAURANT_CREATED = 'restaurant_created'
  RESTAURANT_UPDATED = 'restaurant_updated'
  RESTAURANT_VIEWED = 'restaurant_viewed'
  RESTAURANT_DELETED = 'restaurant_deleted'

  # Menu Events
  MENU_CREATED = 'menu_created'
  MENU_UPDATED = 'menu_updated'
  MENU_VIEWED = 'menu_viewed'
  MENU_DELETED = 'menu_deleted'
  MENU_ITEM_ADDED = 'menu_item_added'
  MENU_ITEM_UPDATED = 'menu_item_updated'
  MENU_ITEM_DELETED = 'menu_item_deleted'

  # Order Events
  ORDER_STARTED = 'order_started'
  ORDER_ITEM_ADDED = 'order_item_added'
  ORDER_ITEM_REMOVED = 'order_item_removed'
  ORDER_COMPLETED = 'order_completed'
  ORDER_CANCELLED = 'order_cancelled'

  # Business Events
  PLAN_SELECTED = 'plan_selected'
  PLAN_UPGRADED = 'plan_upgraded'
  PLAN_DOWNGRADED = 'plan_downgraded'
  SUBSCRIPTION_CANCELLED = 'subscription_cancelled'

  # Feature Usage Events
  FEATURE_USED = 'feature_used'
  QR_CODE_GENERATED = 'qr_code_generated'
  QR_CODE_SCANNED = 'qr_code_scanned'
  TEMPLATE_USED = 'template_used'

  class << self
    delegate_missing_to :instance
  end

  def initialize
    @client = Analytics
  end

  # Track events with user context
  def track_user_event(user, event, properties = {})
    return unless should_track?

    base_properties = {
      timestamp: Time.current,
      user_agent: current_user_agent,
      ip: current_ip_address
    }

    @client.track(
      user_id: user.id,
      event: event,
      properties: base_properties.merge(properties),
      context: user_context(user)
    )
  rescue StandardError => e
    Rails.logger.error "Analytics tracking failed: #{e.message}"
  end

  # Track anonymous events
  def track_anonymous_event(anonymous_id, event, properties = {})
    return unless should_track?

    base_properties = {
      timestamp: Time.current,
      user_agent: current_user_agent,
      ip: current_ip_address
    }

    @client.track(
      anonymous_id: anonymous_id,
      event: event,
      properties: base_properties.merge(properties)
    )
  rescue StandardError => e
    Rails.logger.error "Analytics tracking failed: #{e.message}"
  end

  # Identify user with traits
  def identify_user(user, traits = {})
    return unless should_track?

    default_traits = {
      name: user.name,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at,
      restaurants_count: user.restaurants.count,
      locale: I18n.locale
    }

    @client.identify(
      user_id: user.id,
      traits: default_traits.merge(traits),
      context: user_context(user)
    )
  rescue StandardError => e
    Rails.logger.error "Analytics identification failed: #{e.message}"
  end

  # Track page views
  def track_page_view(user_or_anonymous_id, page_name, properties = {})
    return unless should_track?

    base_properties = {
      timestamp: Time.current,
      user_agent: current_user_agent,
      ip: current_ip_address,
      path: current_path,
      referrer: current_referrer
    }

    if user_or_anonymous_id.is_a?(User)
      @client.page(
        user_id: user_or_anonymous_id.id,
        name: page_name,
        properties: base_properties.merge(properties),
        context: user_context(user_or_anonymous_id)
      )
    else
      @client.page(
        anonymous_id: user_or_anonymous_id,
        name: page_name,
        properties: base_properties.merge(properties)
      )
    end
  rescue StandardError => e
    Rails.logger.error "Analytics page tracking failed: #{e.message}"
  end

  # Onboarding specific methods
  def track_onboarding_started(user, source = nil)
    track_user_event(user, ONBOARDING_STARTED, {
      source: source,
      user_created_at: user.created_at
    })
  end

  def track_onboarding_step_completed(user, step, step_data = {})
    track_user_event(user, ONBOARDING_STEP_COMPLETED, {
      step: step,
      step_name: step_name_for(step),
      time_on_step: calculate_step_time(user, step),
      total_progress: calculate_progress_percentage(step)
    }.merge(step_data))
  end

  def track_onboarding_step_failed(user, step, error_message = nil)
    track_user_event(user, ONBOARDING_STEP_FAILED, {
      step: step,
      step_name: step_name_for(step),
      error_message: error_message,
      time_on_step: calculate_step_time(user, step)
    })
  end

  def track_onboarding_completed(user, completion_data = {})
    onboarding = user.onboarding_session
    
    track_user_event(user, ONBOARDING_COMPLETED, {
      total_time: calculate_total_onboarding_time(user),
      restaurant_type: onboarding&.restaurant_type,
      cuisine_type: onboarding&.cuisine_type,
      menu_items_count: onboarding&.menu_items&.length || 0,
      selected_plan: onboarding&.selected_plan_id,
      completion_rate: 100
    }.merge(completion_data))
  end

  def track_restaurant_created(user, restaurant)
    track_user_event(user, RESTAURANT_CREATED, {
      restaurant_id: restaurant.id,
      restaurant_name: restaurant.name,
      restaurant_type: restaurant.restaurant_type,
      cuisine_type: restaurant.cuisine_type,
      location: restaurant.address1,
      phone: restaurant.phone.present?,
      via_onboarding: true # Always true when called from onboarding
    })
  end

  def track_menu_created(user, menu)
    track_user_event(user, MENU_CREATED, {
      menu_id: menu.id,
      menu_name: menu.name,
      restaurant_id: menu.restaurant_id,
      items_count: menu.menuitems.count,
      sections_count: menu.menusections.count,
      via_onboarding: true # Always true when called from onboarding
    })
  end

  def track_feature_usage(user, feature_name, feature_data = {})
    track_user_event(user, FEATURE_USED, {
      feature: feature_name,
      restaurant_id: current_restaurant_id
    }.merge(feature_data))
  end

  def track_template_usage(user, template_type, template_data = {})
    track_user_event(user, TEMPLATE_USED, {
      template_type: template_type,
      restaurant_id: current_restaurant_id
    }.merge(template_data))
  end

  private

  def should_track?
    Rails.env.production? || Rails.env.staging? || ENV['FORCE_ANALYTICS'] == 'true'
  end

  def user_context(user)
    {
      locale: I18n.locale,
      timezone: Time.zone.name,
      user_agent: current_user_agent,
      ip: current_ip_address
    }
  end

  def step_name_for(step)
    case step.to_i
    when 1 then 'account_details'
    when 2 then 'restaurant_details'
    when 3 then 'plan_selection'
    when 4 then 'menu_creation'
    when 5 then 'completion'
    else 'unknown'
    end
  end

  def calculate_step_time(user, step)
    # This would need to be implemented based on session tracking
    # For now, return nil
    nil
  end

  def calculate_progress_percentage(step)
    (step.to_i / 5.0 * 100).round
  end

  def calculate_total_onboarding_time(user)
    onboarding = user.onboarding_session
    return nil unless onboarding

    if onboarding.completed? && onboarding.created_at
      ((onboarding.updated_at - onboarding.created_at) / 1.minute).round(2)
    end
  end

  # These methods would be set by middleware or controller concerns
  def current_user_agent
    Thread.current[:analytics_user_agent]
  end

  def current_ip_address
    Thread.current[:analytics_ip_address]
  end

  def current_path
    Thread.current[:analytics_path]
  end

  def current_referrer
    Thread.current[:analytics_referrer]
  end

  def current_restaurant_id
    Thread.current[:analytics_restaurant_id]
  end
end
