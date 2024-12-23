class HomeController < ApplicationController
  layout "marketing", :only => [ :index, :terms, :privacy ]

  def index
      Analytics.track(
        anonymous_id: session[:session_id],
        event: 'home.index'
      )
  end

  def terms
      Analytics.track(
        anonymous_id: session[:session_id],
        event: 'home.terms'
      )
  end

  def privacy
      Analytics.track(
        anonymous_id: session[:session_id],
        event: 'home.privacy'
      )
  end
end
