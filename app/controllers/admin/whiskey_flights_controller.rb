# frozen_string_literal: true

module Admin
  class WhiskeyFlightsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_restaurant
    before_action :set_flight, only: %i[edit update destroy publish archive regenerate]

    after_action :verify_authorized

    def index
      authorize @restaurant, :show?
      @flights = WhiskeyFlight.where(menu: @restaurant.menus).order(created_at: :desc)
    end

    def new
      authorize @restaurant, :show?
      @flight = WhiskeyFlight.new(menu: @restaurant.menus.first, source: :manual)
      @menus = @restaurant.menus.where(status: Menu.statuses[:active])
      @whiskey_items = whiskey_items_for_menu(@menus.first)
    end

    def edit
      authorize @restaurant, :show?
      @menus = @restaurant.menus.where(status: Menu.statuses[:active])
      @whiskey_items = whiskey_items_for_menu(@flight.menu)
    end

    def create
      authorize @restaurant, :show?

      menu = @restaurant.menus.find(params[:whiskey_flight][:menu_id])
      @flight = WhiskeyFlight.new(flight_params.merge(menu: menu, source: :manual))

      if params[:whiskey_flight][:item_ids].present?
        item_ids = Array(params[:whiskey_flight][:item_ids]).map(&:to_i).first(3)
        notes = Array(params[:whiskey_flight][:item_notes])
        @flight.items = item_ids.each_with_index.map do |id, idx|
          { 'menuitem_id' => id, 'position' => idx + 1, 'note' => notes[idx].to_s }
        end

        prices = Menuitem.where(id: item_ids).pluck(:price).compact.map(&:to_f)
        @flight.total_price = prices.sum.round(2)
      end

      @flight.theme_key = "manual_#{Time.current.to_i}" if @flight.theme_key.blank?

      if @flight.save
        redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: 'Flight created'
      else
        @menus = @restaurant.menus.where(status: Menu.statuses[:active])
        @whiskey_items = whiskey_items_for_menu(menu)
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @restaurant, :show?

      if params[:whiskey_flight][:item_ids].present?
        item_ids = Array(params[:whiskey_flight][:item_ids]).map(&:to_i).first(3)
        notes = Array(params[:whiskey_flight][:item_notes])
        @flight.items = item_ids.each_with_index.map do |id, idx|
          { 'menuitem_id' => id, 'position' => idx + 1, 'note' => notes[idx].to_s }
        end

        prices = Menuitem.where(id: item_ids).pluck(:price).compact.map(&:to_f)
        @flight.total_price = prices.sum.round(2)
      end

      if @flight.update(flight_params)
        redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: 'Flight updated'
      else
        @menus = @restaurant.menus.where(status: Menu.statuses[:active])
        @whiskey_items = whiskey_items_for_menu(@flight.menu)
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @restaurant, :show?
      @flight.destroy
      redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: 'Flight deleted', status: :see_other
    end

    def publish
      authorize @restaurant, :show?
      @flight.update!(status: :published)
      redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: "\"#{@flight.title}\" published"
    end

    def archive
      authorize @restaurant, :show?
      @flight.update!(status: :archived)
      redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: "\"#{@flight.title}\" archived"
    end

    def regenerate
      authorize @restaurant, :show?

      if @flight.manual?
        redirect_to admin_whiskey_flights_restaurant_path(@restaurant), alert: 'Cannot regenerate manual flights'
        return
      end

      Menu::GenerateWhiskeyFlightsJob.perform_later(@flight.menu_id)
      redirect_to admin_whiskey_flights_restaurant_path(@restaurant), notice: 'Regeneration queued'
    end

    private

    def set_restaurant
      rid = params[:id].presence || params[:restaurant_id]
      @restaurant = Restaurant.find(rid)
    end

    def set_flight
      @flight = WhiskeyFlight.find(params[:flight_id])
    end

    def flight_params
      params.require(:whiskey_flight).permit(:title, :narrative, :custom_price, :theme_key)
    end

    def whiskey_items_for_menu(menu)
      return [] unless menu

      menu.menuitems
        .joins(:menusection)
        .where('menusections.archived IS NOT TRUE')
        .where(itemtype: :whiskey, status: 'active')
        .order(:name)
    end
  end
end
