class HomeController < ApplicationController
  layout "marketing", :only => [ :index, :terms, :privacy ]

  def index
      if session[:session_id]
          Analytics.track(
            anonymous_id: session[:session_id],
            event: 'home.index'
          )
      end
      @demoMenu = Menu.(id: 3)
      if @demoMenu
          @qrDemoURL = Rails.application.routes.url_helpers.menu_url(@demoMenu, :host => request.host_with_port)
          if request.host != 'localhost'
              @qrDemoURL.sub! 'http://', 'https://'
          end
          @qrDemoURL.sub! '/edit', ''
      end
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
