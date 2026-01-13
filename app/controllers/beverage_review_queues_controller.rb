class BeverageReviewQueuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  after_action :verify_authorized

  def show
    authorize @restaurant, :show?

    menus = @restaurant.menus.where(status: Menu.statuses[:active])

    @needs_review_items = Menuitem
      .joins(menusection: :menu)
      .where(menus: { id: menus.select(:id) })
      .where(sommelier_needs_review: true)
      .order('menus.updated_at DESC, menusections.sequence ASC, menuitems.sequence ASC')
      .limit(500)

    @latest_runs = BeveragePipelineRun
      .where(restaurant_id: @restaurant.id)
      .order(created_at: :desc)
      .limit(10)
  end

  def review
    authorize @restaurant, :show?

    menuitem = Menuitem
      .joins(menusection: :menu)
      .where(menus: { restaurant_id: @restaurant.id })
      .find(params[:menuitem_id])

    lock = ActiveModel::Type::Boolean.new.cast(params[:lock])

    Menuitem.transaction do
      menuitem.update_columns(sommelier_needs_review: false, updated_at: Time.current)
      if lock
        MenuItemProductLink.where(menuitem_id: menuitem.id).update_all(locked: true)
      end
    end

    begin
      menuitem.expire_cache if menuitem.respond_to?(:expire_cache)
    rescue StandardError
      nil
    end

    redirect_to beverage_review_queue_restaurant_path(@restaurant), notice: 'Marked as reviewed', status: :see_other
  end

  private

  def set_restaurant
    rid = params[:id].presence || params[:restaurant_id]
    @restaurant = Restaurant.find(rid)
  end
end
