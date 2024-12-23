class HomeController < ApplicationController
  layout "marketing", :only => [ :index, :terms, :privacy ]

  def index
      Analytics.track(
          event: 'home.index'
      )
  end

  def terms
      Analytics.track(
          event: 'home.terms'
      )
  end

  def privacy
      Analytics.track(
          event: 'home.privacy'
      )
  end
end
