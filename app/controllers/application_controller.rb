class ApplicationController < ActionController::Base
  impersonates :user
  include Pundit::Authorization

  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_current_employee

  protected
    def set_current_employee
        if current_user
            @current_employee = Employee.where(user_id: current_user.id).first
            @restaurants = Restaurant.where( user: current_user)
        end
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
    end
end
