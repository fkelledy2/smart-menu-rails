class HomeController < ApplicationController
  layout "marketing", :only => [ :index, :terms, :privacy ]

  def index
      if session[:session_id]
          Analytics.track(
            anonymous_id: session[:session_id],
            event: 'home.index'
          )
      end
      @qrHost = request.host_with_port
      if request.host == 'localhost'
          @demoMenu = Smartmenu.where(restaurant_id: 1, menu_id: 1).first
      else
          @demoMenu = Smartmenu.where(restaurant_id: 3, menu_id: 3).first
      end
      @plans = Plan.all
      @features = Feature.all
      @contact = Contact.new
  end

  def terms
      if session[:session_id]
          Analytics.track(
            anonymous_id: session[:session_id],
            event: 'home.terms'
          )
      end
  end

  def privacy
      if session[:session_id]
          Analytics.track(
            anonymous_id: session[:session_id],
            event: 'home.privacy'
          )
      end
  end
end
