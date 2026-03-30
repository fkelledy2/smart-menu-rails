# frozen_string_literal: true

module Admin
  class MarketingQrCodesController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :require_mellow_admin!

    before_action :set_qr_code, only: %i[show edit update destroy link unlink print]

    def index
      @qr_codes = policy_scope(MarketingQrCode).order(created_at: :desc)
      authorize MarketingQrCode
    end

    def show
      authorize @qr_code
    end

    def new
      @qr_code = MarketingQrCode.new
      authorize @qr_code
    end

    def edit
      authorize @qr_code
    end

    def create
      @qr_code = MarketingQrCode.new(create_params)
      @qr_code.created_by_user_id = current_user.id
      authorize @qr_code

      if @qr_code.save
        redirect_to admin_marketing_qr_code_path(@qr_code), notice: 'Marketing QR code created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @qr_code

      if @qr_code.update(update_params)
        redirect_to admin_marketing_qr_code_path(@qr_code), notice: 'Marketing QR code updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @qr_code
      @qr_code.update!(status: :archived)
      redirect_to admin_marketing_qr_codes_path, notice: 'Marketing QR code archived.', status: :see_other
    end

    def link
      authorize @qr_code

      restaurant = Restaurant.find_by(id: params[:restaurant_id])

      unless restaurant
        redirect_to admin_marketing_qr_code_path(@qr_code), alert: 'Restaurant not found.'
        return
      end

      menu         = params[:menu_id].present? ? restaurant.menus.find_by(id: params[:menu_id]) : nil
      tablesetting = params[:tablesetting_id].present? ? restaurant.tablesettings.find_by(id: params[:tablesetting_id]) : nil

      result = MarketingQrCodes::LinkService.call(
        marketing_qr_code: @qr_code,
        restaurant: restaurant,
        menu: menu,
        tablesetting: tablesetting,
      )

      if result.success?
        redirect_to admin_marketing_qr_code_path(@qr_code), notice: 'QR code linked successfully.'
      else
        redirect_to admin_marketing_qr_code_path(@qr_code), alert: "Could not link QR code: #{result.error}"
      end
    end

    def unlink
      authorize @qr_code

      @qr_code.update!(
        status: :unlinked,
        restaurant: nil,
        menu: nil,
        tablesetting: nil,
        smartmenu: nil,
      )

      redirect_to admin_marketing_qr_code_path(@qr_code), notice: 'QR code unlinked.', status: :see_other
    end

    def print
      authorize @qr_code
      render :print, layout: false
    end

    private

    def set_qr_code
      @qr_code = MarketingQrCode.find_by(id: params[:id])
      head :not_found unless @qr_code
    end

    def create_params
      params.require(:marketing_qr_code).permit(:name, :campaign, :holding_url)
    end

    def update_params
      params.require(:marketing_qr_code).permit(:name, :campaign, :holding_url)
    end

    def require_mellow_admin!
      return if current_user&.email.to_s.end_with?('@mellow.menu')

      redirect_to root_path, alert: 'Access denied. mellow.menu staff only.', status: :see_other
    end
  end
end
