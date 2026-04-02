module Admin
  class FeatureFlagsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!

    def index
      @features = Flipper.features.sort_by(&:name)
    end

    def create
      name = params[:name].to_s.strip.downcase.gsub(/\s+/, '_')
      if name.blank?
        redirect_to admin_feature_flags_path, alert: 'Name cannot be blank.' and return
      end
      Flipper.add(name)
      redirect_to admin_feature_flags_path, notice: "Feature '#{name}' added."
    end

    def update
      feature = Flipper[params[:id]]
      case params[:state]
      when 'enable'
        feature.enable
      when 'disable'
        feature.disable
      end
      redirect_to admin_feature_flags_path, notice: "Feature '#{feature.name}' updated."
    end

    def destroy
      Flipper.remove(params[:id])
      redirect_to admin_feature_flags_path, notice: "Feature '#{params[:id]}' removed."
    end
  end
end
