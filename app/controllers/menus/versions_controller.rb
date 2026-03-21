# frozen_string_literal: true

module Menus
  class VersionsController < BaseController
    before_action :authenticate_user!
    before_action :set_menu
    before_action :ensure_owner_restaurant_context!, only: %i[create_version activate_version]

    # GET /restaurants/:restaurant_id/menus/:id/versions
    def versions
      authorize @menu, :update?

      versions = @menu.menu_versions.order(version_number: :desc)
      active = @menu.active_menu_version

      render json: {
        menu_id: @menu.id,
        active_menu_version_id: active&.id,
        count: versions.size,
        versions: versions.map do |v|
          {
            id: v.id,
            version_number: v.version_number,
            is_active: v.is_active,
            starts_at: v.starts_at,
            ends_at: v.ends_at,
            created_by_user_id: v.created_by_user_id,
            created_at: v.created_at,
          }
        end,
      }
    end

    # GET /restaurants/:restaurant_id/menus/:id/versions/:from_version_id/diff/:to_version_id
    def version_diff
      authorize @menu, :update?

      from_version = @menu.menu_versions.find(params[:from_version_id])
      to_version = @menu.menu_versions.find(params[:to_version_id])
      diff = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

      render json: {
        menu_id: @menu.id,
        from_version_id: from_version.id,
        to_version_id: to_version.id,
        diff: diff,
      }
    end

    # GET /restaurants/:restaurant_id/menus/:id/versions/diff
    def versions_diff
      authorize @menu, :update?

      from_version = @menu.menu_versions.find(params[:from_version_id])
      to_version = @menu.menu_versions.find(params[:to_version_id])
      diff = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

      respond_to do |format|
        format.json do
          render json: {
            menu_id: @menu.id,
            from_version_id: from_version.id,
            to_version_id: to_version.id,
            diff: diff,
          }
        end
        format.html do
          if turbo_frame_request_id == 'menu_versions_diff'
            render partial: 'menus/sections/version_diff_2025',
                   locals: {
                     menu: @menu,
                     restaurant: @restaurant || @menu.restaurant,
                     from_version: from_version,
                     to_version: to_version,
                     diff: diff,
                   }
          else
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions')
          end
        end
      end
    end

    # POST /restaurants/:restaurant_id/menus/:id/create_version
    def create_version
      authorize @menu, :update?

      menu_version = MenuVersion.create_from_menu!(menu: @menu, user: current_user)

      respond_to do |format|
        format.json do
          render json: {
            menu_id: @menu.id,
            menu_version: {
              id: menu_version.id,
              version_number: menu_version.version_number,
              is_active: menu_version.is_active,
              starts_at: menu_version.starts_at,
              ends_at: menu_version.ends_at,
              created_at: menu_version.created_at,
            },
          }
        end
        format.html do
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions'),
                      status: :see_other
        end
      end
    end

    # POST /restaurants/:restaurant_id/menus/:id/activate_version
    def activate_version
      authorize @menu, :update?

      menu_version = @menu.menu_versions.find(params[:menu_version_id])

      context_restaurant = @restaurant || @menu.owner_restaurant || @menu.restaurant
      zone_name = begin
        context_restaurant.respond_to?(:timezone) ? context_restaurant.timezone.to_s.presence : nil
      rescue StandardError => e
        Rails.logger.warn("[Menus::VersionsController] timezone lookup failed: #{e.message}")
        nil
      end
      zone_name ||= Time.zone.name

      parse_in_zone = lambda do |raw|
        s = raw.to_s
        next nil if s.blank?

        Time.use_zone(zone_name) do
          if s.end_with?('Z') || s.match?(/[+-]\d\d:\d\d\z/)
            Time.iso8601(s)
          else
            Time.zone.parse(s)
          end
        rescue ArgumentError
          begin
            Time.zone.parse(s)
          rescue StandardError => e
            Rails.logger.warn("[Menus::VersionsController] date parse fallback failed: #{e.message}")
            nil
          end
        end
      end

      starts_at = parse_in_zone.call(params[:starts_at])
      ends_at = parse_in_zone.call(params[:ends_at])

      MenuVersionActivationService.activate!(menu_version: menu_version, starts_at: starts_at, ends_at: ends_at)

      respond_to do |format|
        format.json do
          render json: {
            menu_id: @menu.id,
            active_menu_version_id: @menu.active_menu_version&.id,
            activated_menu_version_id: menu_version.id,
            menu_version: {
              id: menu_version.id,
              version_number: menu_version.version_number,
              is_active: menu_version.is_active,
              starts_at: menu_version.starts_at,
              ends_at: menu_version.ends_at,
            },
          }
        end
        format.html do
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions'),
                      status: :see_other
        end
      end
    end
  end
end
