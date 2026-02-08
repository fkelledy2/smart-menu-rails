class AlcoholOrderEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  def index
    authorize @restaurant, :show?
    events = AlcoholOrderEvent.where(restaurant_id: @restaurant.id)
      .includes(:ordr, :ordritem, :menuitem)
      .order(created_at: :desc)

    respond_to do |format|
      format.html do
        @events = events.limit(200)
      end
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=alcohol_events_#{@restaurant.id}_#{Time.zone.now.to_i}.csv"
        headers['Content-Type'] ||= 'text/csv'
        self.response_body = csv_enumerator(events)
      end
      format.json { render json: events.as_json(only: %i[id ordr_id ordritem_id menuitem_id employee_id customer_sessionid alcoholic abv alcohol_classification age_check_acknowledged acknowledged_at created_at]) }
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def csv_enumerator(relation)
    Enumerator.new do |y|
      require 'csv'
      y << CSV.generate_line(%w[id order_id order_item_id menuitem_id employee_id customer_sessionid alcoholic abv classification acknowledged acknowledged_at created_at])
      relation.find_each(batch_size: 1000) do |e|
        y << CSV.generate_line([
          e.id, e.ordr_id, e.ordritem_id, e.menuitem_id, e.employee_id, e.customer_sessionid,
          e.alcoholic, e.abv, e.alcohol_classification, e.age_check_acknowledged, e.acknowledged_at, e.created_at,
        ])
      end
    end
  end
end
