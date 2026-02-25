class WhiskeyImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  after_action :verify_authorized

  def new
    authorize @restaurant, :show?
    @menus = @restaurant.menus.where(status: Menu.statuses[:active])
  end

  def create
    authorize @restaurant, :show?

    menu = @restaurant.menus.find(params[:menu_id])

    if params[:csv_file].blank?
      redirect_to new_whiskey_import_restaurant_path(@restaurant), alert: 'Please select a CSV file'
      return
    end

    csv_content = params[:csv_file].read
    importer = BeverageIntelligence::WhiskeyCsvImporter.new(menu)
    @result = importer.import(csv_content)

    flash[:notice] = "Import complete: #{@result.matched.size} matched, #{@result.unmatched.size} unmatched, #{@result.errors.size} errors"
    redirect_to beverage_review_queue_restaurant_path(@restaurant)
  rescue ArgumentError => e
    redirect_to new_whiskey_import_restaurant_path(@restaurant), alert: e.message
  end

  private

  def set_restaurant
    rid = params[:id].presence || params[:restaurant_id]
    @restaurant = Restaurant.find(rid)
  end
end
