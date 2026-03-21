# frozen_string_literal: true

module Menus
  class LocalizationController < BaseController
    before_action :authenticate_user!
    before_action :set_menu
    before_action :ensure_owner_restaurant_context!, only: %i[localize]

    # POST /restaurants/:restaurant_id/menus/:id/localize
    def localize
      authorize @menu, :update?

      restaurant = @restaurant || @menu.restaurant
      active_locales = Restaurantlocale.where(restaurant: restaurant, status: 'active')

      if active_locales.empty?
        flash.now[:alert] = t('menus.controller.no_active_locales', default: 'No active locales configured for this restaurant.')
        redirect_to edit_restaurant_menu_path(restaurant, @menu) and return
      end

      force = params[:force].to_s == 'true'

      items_count = @menuItemCount.presence || @menu.menuitems.count
      total = active_locales.count * items_count
      jid = MenuLocalizationJob.perform_async('menu', @menu.id, force)

      begin
        Sidekiq.redis do |r|
          r.setex("localize:#{jid}", 24 * 3600, {
            status: 'queued',
            current: 0,
            total: total,
            message: 'Queued menu localization',
            menu_id: @menu.id,
          }.to_json,)
        end
      rescue StandardError => e
        Rails.logger.warn("[Menus::LocalizationController] Failed to init localization progress for #{jid}: #{e.message}")
      end

      respond_to do |format|
        format.html do
          flash_message = if force
                            t('menus.controller.localization_queued_force',
                              default: "Menu re-translation has been queued. This will process #{total} item translations across #{active_locales.count} locale(s).",)
                          else
                            t('menus.controller.localization_queued',
                              default: "Menu localization has been queued. This will process up to #{total} item translations across #{active_locales.count} locale(s).",)
                          end
          flash[:notice] = flash_message
          redirect_to edit_restaurant_menu_path(restaurant, @menu)
        end
        format.json do
          render json: { job_id: jid, total: total, status: 'queued' }
        end
      end
    end

    # GET /restaurants/:restaurant_id/menus/:id/localization_progress
    def localization_progress
      authorize @menu, :update?

      jid = params[:job_id].to_s
      payload = nil
      begin
        Sidekiq.redis do |r|
          json = r.get("localize:#{jid}")
          payload = json.present? ? JSON.parse(json) : {}
        end
      rescue StandardError => e
        Rails.logger.warn("[Menus::LocalizationController] Localization progress read failed for #{jid}: #{e.message}")
        payload ||= {}
      end

      payload ||= {}
      payload['job_id'] = jid
      payload['menu_id'] ||= @menu.id

      render json: payload
    end
  end
end
