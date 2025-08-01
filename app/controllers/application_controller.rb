class ApplicationController < ActionController::Base
  impersonates :user
  include Pundit::Authorization
  around_action :switch_locale

  def switch_locale(&action)
      if request.env["HTTP_ACCEPT_LANGUAGE"] != nil
          @locale = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
          I18n.with_locale(@locale, &action)
      end
  end

  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_current_employee
  before_action :set_permissions

  protected
    def set_permissions
      @canAddRestaurant = false
      if current_user && current_user.plan
          @restaurants = Restaurant.where( user: current_user, archived: false)
          if @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
              @canAddRestaurant = true
          end
      end
    end

    def set_current_employee
        if current_user
            @current_employee = Employee.where(user_id: current_user.id).first
            @restaurants = Restaurant.where( user: current_user)
            @userplan = Userplan.where( user_id: @current_user.id).first
            if @userplan == nil
                @userplan = Userplan.new
            end
        else
            @userplan = Userplan.new
        end
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
    end
end
