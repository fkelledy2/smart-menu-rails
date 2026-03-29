# frozen_string_literal: true

module Menus
  class AiController < BaseController
    before_action :authenticate_user!
    before_action :set_menu
    before_action :ensure_owner_restaurant_context!, only: %i[regenerate_images polish generate_pairings]

    # POST /restaurants/:restaurant_id/menus/:id/regenerate_images
    def regenerate_images
      authorize @menu, :update?

      if params[:generate_ai] == 'true'
        total = Genimage.where(menu_id: @menu.id).count
        jid = MenuItemImageBatchJob.perform_async(@menu.id)

        begin
          Sidekiq.redis do |r|
            r.setex("image_gen:#{jid}", 24 * 3600, {
              status: 'queued',
              current: 0,
              total: total,
              message: 'Queued AI image generation',
              menu_id: @menu.id,
            }.to_json,)
          end
        rescue StandardError => e
          Rails.logger.warn("[Menus::AiController] Failed to init image gen progress for #{jid}: #{e.message}")
        end

        respond_to do |format|
          format.html do
            flash[:notice] = t('menus.controller.ai_image_generation_queued')
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
          end
          format.json { render json: { job_id: jid, total: total, status: 'queued' } }
        end
      else
        RegenerateMenuWebpJob.perform_async(@menu.id)
        flash[:notice] = t('menus.controller.webp_regeneration_queued')
        redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
      end
    end

    # GET /restaurants/:restaurant_id/menus/:id/image_generation_progress
    def image_generation_progress
      authorize @menu, :update?

      jid = params[:job_id].to_s
      payload = nil
      begin
        Sidekiq.redis do |r|
          json = r.get("image_gen:#{jid}")
          payload = json.present? ? JSON.parse(json) : {}
        end
      rescue StandardError => e
        Rails.logger.warn("[Menus::AiController] Progress read failed for #{jid}: #{e.message}")
        payload ||= {}
      end

      payload ||= {}
      payload['job_id'] = jid
      payload['menu_id'] ||= @menu.id

      render json: payload
    end

    # POST /restaurants/:restaurant_id/menus/:id/polish
    def polish
      authorize @menu, :update?

      total = @menuItemCount.presence || @menu.menuitems.count
      jid = AiMenuPolisherJob.perform_async(@menu.id)

      begin
        Sidekiq.redis do |r|
          r.setex("polish:#{jid}", 24 * 3600, {
            status: 'queued',
            current: 0,
            total: total,
            message: 'Queued AI menu polishing',
            menu_id: @menu.id,
          }.to_json,)
        end
      rescue StandardError => e
        Rails.logger.warn("[Menus::AiController] Failed to init polish progress for #{jid}: #{e.message}")
      end

      respond_to do |format|
        format.html do
          flash[:notice] = t('menus.controller.polish_queued', default: 'AI menu polishing has been queued.')
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'details')
        end
        format.json { render json: { job_id: jid, total: total, status: 'queued' } }
      end
    end

    # GET /restaurants/:restaurant_id/menus/:id/polish_progress
    def polish_progress
      authorize @menu, :update?

      jid = params[:job_id].to_s
      payload = nil
      begin
        Sidekiq.redis do |r|
          json = r.get("polish:#{jid}")
          payload = json.present? ? JSON.parse(json) : {}
        end
      rescue StandardError => e
        Rails.logger.warn("[Menus::AiController] Polish progress read failed for #{jid}: #{e.message}")
        payload ||= {}
      end

      payload ||= {}
      payload['job_id'] = jid
      payload['menu_id'] ||= @menu.id

      render json: payload
    end

    # POST /restaurants/:restaurant_id/menus/:id/generate_pairings
    def generate_pairings
      authorize @menu, :update?

      restaurant = @restaurant || @menu.restaurant

      engine = BeverageIntelligence::PairingEngine.new
      pairings_count = engine.generate_for_menu(@menu)

      Rails.logger.info("[Menus::AiController] Generated #{pairings_count} pairings for menu ##{@menu.id}")

      respond_to do |format|
        format.html do
          flash[:notice] = t('menus.controller.generate_pairings_queued', default: 'Food & drink pairing generation complete.')
          redirect_to edit_restaurant_menu_path(restaurant, @menu, section: 'details')
        end
        format.json do
          pairings = PairingRecommendation
            .joins(:drink_menuitem, :food_menuitem)
            .where(drink_menuitem_id: @menu.menuitems.select(:id))
            .order(score: :desc)
            .limit(100)
            .map do |p|
              {
                drink_name: p.drink_menuitem.name,
                drink_type: p.drink_menuitem.itemtype,
                food_name: p.food_menuitem.name,
                score: p.score.to_f.round(4),
                pairing_type: p.pairing_type,
                rationale: p.rationale,
              }
            end

          render json: { pairings_count: pairings_count, pairings: pairings }
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Menus::AiController] generate_pairings failed: #{e.class}: #{e.message}")
      respond_to do |format|
        format.html do
          flash[:alert] = t('menus.controller.generate_pairings_failed', default: 'Failed to generate pairings.')
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'details')
        end
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
  end
end
