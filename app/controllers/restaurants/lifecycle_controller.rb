# frozen_string_literal: true

module Restaurants
  class LifecycleController < BaseController
    before_action :set_restaurant

    # PATCH /restaurants/:id/archive
    def archive
      authorize @restaurant

      RestaurantArchivalService.archive_async(
        restaurant_id: @restaurant.id,
        archived_by_id: current_user&.id,
        reason: params[:reason],
      )

      respond_to do |format|
        format.html { redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant')) }
        format.json { render json: { success: true }, status: :accepted }
      end
    end

    # PATCH /restaurants/:id/restore
    def restore
      authorize @restaurant

      RestaurantArchivalService.restore_async(
        restaurant_id: @restaurant.id,
        archived_by_id: current_user&.id,
        reason: params[:reason],
      )

      respond_to do |format|
        format.html { redirect_to restaurants_url, notice: t('common.flash.restored', resource: t('activerecord.models.restaurant')) }
        format.json { render json: { success: true }, status: :accepted }
      end
    end

    # PATCH /restaurants/:id/publish_preview
    def publish_preview
      authorize @restaurant

      unless current_user&.super_admin?
        redirect_to edit_restaurant_path(@restaurant), alert: 'Only super admins can publish previews.' and return
      end

      if params[:unpublish].present?
        @restaurant.update!(preview_enabled: false, preview_indexable: false)
        redirect_to edit_restaurant_path(@restaurant), notice: 'Preview unpublished.'
      else
        ActiveRecord::Base.transaction do
          @restaurant.update!(
            preview_enabled: true,
            preview_published_at: @restaurant.preview_published_at || Time.current,
          )

          @restaurant.menus.where(status: 'active').find_each do |menu|
            next if Smartmenu.exists?(restaurant_id: @restaurant.id, menu_id: menu.id, tablesetting_id: nil)

            Smartmenu.create!(
              restaurant: @restaurant,
              menu: menu,
              slug: SecureRandom.uuid,
            )
          end
        end

        redirect_to edit_restaurant_path(@restaurant), notice: 'Preview published for all menus.'
      end
    end
  end
end
