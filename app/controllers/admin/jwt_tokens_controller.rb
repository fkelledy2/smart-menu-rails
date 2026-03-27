# frozen_string_literal: true

module Admin
  class JwtTokensController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_mellow_admin!
    before_action :set_token, only: %i[show revoke send_email download_link]

    def index
      @tokens = policy_scope(AdminJwtToken)
        .includes(:admin_user, :restaurant)
        .order(created_at: :desc)
      authorize AdminJwtToken
    end

    def show
      authorize @token
    end

    def new
      @token = AdminJwtToken.new
      @restaurants = Restaurant.order(:name)
      authorize @token
    end

    def create
      authorize AdminJwtToken, :create?

      result = Jwt::TokenGenerator.call(
        admin_user: current_user,
        restaurant: restaurant_for_create,
        name: token_params[:name],
        description: token_params[:description],
        scopes: Array(token_params[:scopes]),
        expires_in: parse_expiry(token_params[:expiry_preset]),
        rate_limit_per_minute: token_params[:rate_limit_per_minute].to_i.clamp(1, 1000),
        rate_limit_per_hour: token_params[:rate_limit_per_hour].to_i.clamp(1, 10_000),
      )

      if result.success?
        # Store the raw JWT in flash for one-time display only
        flash[:raw_jwt] = result.raw_jwt
        redirect_to admin_jwt_token_path(result.token),
                    notice: 'Token created. Copy the raw JWT below — it will not be shown again.'
      else
        @token = AdminJwtToken.new(token_params.except(:expiry_preset, :restaurant_id))
        @restaurants = Restaurant.order(:name)
        flash.now[:alert] = "Could not create token: #{result.error}"
        render :new, status: :unprocessable_content
      end
    end

    def revoke
      authorize @token, :revoke?

      @token.revoke!
      redirect_to admin_jwt_token_path(@token), notice: 'Token revoked. All subsequent API calls with this token will be rejected.'
    end

    def send_email
      authorize @token, :send_email?

      recipient = params[:recipient_email].presence || @token.restaurant.email
      unless recipient
        redirect_to admin_jwt_token_path(@token), alert: 'No recipient email available.'
        return
      end

      raw_jwt = params[:raw_jwt].presence
      unless raw_jwt
        redirect_to admin_jwt_token_path(@token),
                    alert: 'The raw JWT is no longer available. A new token must be generated to send via email.'
        return
      end

      JwtTokenMailer.token_delivery(
        jwt_token: @token,
        recipient_email: recipient,
        raw_jwt: raw_jwt,
      ).deliver_later

      redirect_to admin_jwt_token_path(@token),
                  notice: "Token email queued for delivery to #{recipient}."
    end

    def download_link
      authorize @token, :download_link?

      raw_jwt = params[:raw_jwt].presence
      unless raw_jwt
        redirect_to admin_jwt_token_path(@token),
                    alert: 'The raw JWT is no longer available. A new token must be generated.'
        return
      end

      # Build a data-URI download so the browser saves a .txt file
      send_data raw_jwt,
                filename: "api-token-#{@token.restaurant.name.parameterize}-#{@token.id}.txt",
                type: 'text/plain; charset=utf-8',
                disposition: 'attachment'
    end

    private

    def set_token
      @token = AdminJwtToken.find(params[:id])
    end

    def restaurant_for_create
      Restaurant.find(token_params[:restaurant_id])
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, 'Restaurant not found'
    end

    def token_params
      params.require(:admin_jwt_token).permit(
        :restaurant_id,
        :name,
        :description,
        :expiry_preset,
        :rate_limit_per_minute,
        :rate_limit_per_hour,
        scopes: [],
      )
    end

    def parse_expiry(preset)
      AdminJwtToken::EXPIRY_OPTIONS.fetch(preset, 30.days)
    end

    def require_mellow_admin!
      return if current_user&.admin? && current_user&.email.to_s.end_with?('@mellow.menu')

      redirect_to root_path, alert: 'Access denied. mellow.menu staff only.', status: :see_other
    end
  end
end
