class HomeController < ApplicationController
  layout 'marketing', only: %i[index terms privacy]

  def index
    # Set content type to HTML
    response.content_type = 'text/html; charset=utf-8'

    # Set up instance variables
    @qrHost = request.host_with_port
    @demoMenu = if request.host == 'localhost'
                  Smartmenu.where(restaurant_id: 1, menu_id: 1).first
                else
                  Smartmenu.where(restaurant_id: 3, menu_id: 3).first
                end

    @plans = Plan.all
    @features = Feature.all
    @contact = Contact.new
    @testimonials = Testimonial.where(status: 'approved').order(:sequence).all
    @hero_images = HeroImage.approved_for_carousel

    # Set page metadata
    @page_title = 'Mellow Menu - Digital Menu Solution for Restaurants'
    @page_description = 'Create beautiful digital menus, enable online ordering, and provide contactless payment options for your restaurant.'

    # Track homepage view
    if current_user
      AnalyticsService.track_user_event(current_user, 'homepage_viewed', {
        has_restaurants: current_user.restaurants.any?,
        plan_name: current_user.plan&.name,
        user_type: 'authenticated',
      },)
    else
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_anonymous_event(anonymous_id, 'homepage_viewed', {
        user_type: 'anonymous',
        referrer: request.referer,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
      },)
    end

    # Explicitly render the template with layout
    render :index, layout: 'marketing', content_type: 'text/html'
  rescue StandardError => e
    logger.error "Error in HomeController#index: #{e.message}\n#{e.backtrace.join("\n")}"
    render plain: "An error occurred: #{e.message}", status: :internal_server_error, content_type: 'text/plain'
  end

  def terms
    anonymous_id = session[:session_id] ||= SecureRandom.uuid
    AnalyticsService.track_anonymous_event(anonymous_id, 'terms_viewed', {
      page: 'terms_of_service',
      referrer: request.referer,
    },)

    @page_title = 'Terms of Service - Mellow Menu'
    @page_description = 'Read our Terms of Service to understand the rules and guidelines for using Mellow Menu.'

    respond_to do |format|
      format.html { render :terms, status: :ok }
      format.json { render json: { status: 'success', message: 'Terms of Service' } }
    end
  rescue StandardError => e
    logger.error "Error in HomeController#terms: #{e.message}\n#{e.backtrace.join("\n")}"
    render 'errors/500', status: :internal_server_error
  end

  def privacy
    anonymous_id = session[:session_id] ||= SecureRandom.uuid
    AnalyticsService.track_anonymous_event(anonymous_id, 'privacy_viewed', {
      page: 'privacy_policy',
      referrer: request.referer,
    },)

    @page_title = 'Privacy Policy - Mellow Menu'
    @page_description = 'Learn how Mellow Menu collects, uses, and protects your personal information in our Privacy Policy.'

    respond_to do |format|
      format.html { render :privacy, status: :ok }
      format.json { render json: { status: 'success', message: 'Privacy Policy' } }
    end
  rescue StandardError => e
    logger.error "Error in HomeController#privacy: #{e.message}\n#{e.backtrace.join("\n")}"
    render 'errors/500', status: :internal_server_error
  end
end
