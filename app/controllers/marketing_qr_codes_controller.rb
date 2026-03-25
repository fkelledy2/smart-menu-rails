# frozen_string_literal: true

# Public endpoint for marketing QR code resolution.
# Accessible without authentication — handles unlinked holding pages and
# linked redirects to the SmartMenu token URL.
#
# Rate-limited by Rack::Attack (`marketing_qr/ip` throttle).
class MarketingQrCodesController < ApplicationController
  skip_before_action :set_current_employee, raise: false
  skip_before_action :set_permissions,      raise: false
  skip_before_action :redirect_to_onboarding_if_needed, raise: false

  before_action :skip_authorization

  def resolve
    result = MarketingQrCodes::ResolveService.call(token: params[:token])

    case result.outcome
    when :redirect_to_smartmenu
      redirect_to table_link_path(result.smartmenu_public_token), allow_other_host: false, status: :found
    when :holding
      # If the operator set a custom holding URL, redirect there; otherwise render our branded page.
      if result.holding_url != 'https://mellow.menu' && result.qr.holding_url.present?
        redirect_to result.holding_url, allow_other_host: true, status: :found
      else
        @qr = result.qr
        render :holding, layout: 'marketing', status: :ok
      end
    else
      render_not_found
    end
  end

  private

  def render_not_found
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end
end
