class NotificationsController < ApplicationController
  before_action :authenticate_user!
  
  # Pundit authorization
  after_action :verify_policy_scoped, only: [:index]

  def index
    @notifications = policy_scope(current_user.notifications).includes(:event)
  end
end
