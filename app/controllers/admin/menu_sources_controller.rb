module Admin
  class MenuSourcesController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action -> { redirect_to root_path, alert: 'Access denied' unless current_user&.super_admin? }

    def update
      menu_source = MenuSource.find(params[:id])
      menu_source.update!(name: params.dig(:menu_source, :name))

      redirect_back_or_to admin_discovered_restaurant_path(params[:discovered_restaurant_id]), notice: 'Menu source updated', status: :see_other
    end
  end
end
