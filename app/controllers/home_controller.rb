class HomeController < ApplicationController
  layout "marketing", :only => [ :index, :terms, :privacy ]

  def index
  end

  def terms
  end

  def privacy
  end
end
