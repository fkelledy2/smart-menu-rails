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

    # Set page metadata
    @page_title = 'Mellow Menu - Digital Menu Solution for Restaurants'
    @page_description = 'Create beautiful digital menus, enable online ordering, and provide contactless payment options for your restaurant.'

    # Explicitly render the template with layout
    render :index, layout: 'marketing', content_type: 'text/html'
  rescue StandardError => e
    logger.error "Error in HomeController#index: #{e.message}\n#{e.backtrace.join("\n")}"
    render plain: "An error occurred: #{e.message}", status: :internal_server_error, content_type: 'text/plain'
  end

  def terms
    if session[:session_id]
      Analytics.track(
        anonymous_id: session[:session_id],
        event: 'home.terms',
      )
    end

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
    if session[:session_id]
      Analytics.track(
        anonymous_id: session[:session_id],
        event: 'home.privacy',
      )
    end

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
