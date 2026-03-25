# frozen_string_literal: true

class FloorplansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :check_feature_flag

  # GET /restaurants/:restaurant_id/floorplan
  def show
    authorize @restaurant, policy_class: FloorplanPolicy

    # Load all non-archived tablesettings with active order info.
    # Uses left outer join so "available" (no order) tables still appear.
    # Active orders: status not in paid/closed — take the newest per table.
    tablesettings = @restaurant.tablesettings
      .where.not(status: :archived)
      .order(sequence: :asc, id: :asc)

    # Fetch the newest active order per table in two efficient queries.
    # Step 1: find the max id per table (newest order wins) among active orders.
    excluded_statuses = [Ordr.statuses['paid'], Ordr.statuses['closed']]
    newest_ids = Ordr
      .unscoped
      .where(restaurant_id: @restaurant.id)
      .where.not(status: excluded_statuses)
      .group(:tablesetting_id)
      .maximum(:id)
      .values

    # Step 2: load full rows for those ids.
    active_ordrs = if newest_ids.empty?
                     []
                   else
                     Ordr
                       .unscoped
                       .where(id: newest_ids)
                       .select(:id, :tablesetting_id, :status, :created_at, :updated_at,
                               :gross, :ordrparticipants_count, :auto_pay_status, :payment_on_file,)
                   end

    ordr_by_table = active_ordrs.index_by(&:tablesetting_id)

    # Detect tables with multiple active orders (warning case) — single extra count query.
    # Use unscoped to avoid the default orderedAt ORDER BY conflicting with GROUP BY.
    multi_order_table_ids = Ordr
      .unscoped
      .where(restaurant_id: @restaurant.id)
      .where.not(status: excluded_statuses)
      .group(:tablesetting_id)
      .having('COUNT(*) > 1')
      .pluck(:tablesetting_id)
      .to_set

    @table_tiles = tablesettings.map do |ts|
      {
        tablesetting: ts,
        ordr: ordr_by_table[ts.id],
        multi_order_warning: multi_order_table_ids.include?(ts.id),
      }
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: 'Restaurant not found.' }
      format.json { head :not_found }
    end
  end

  def check_feature_flag
    return if Flipper.enabled?(:floorplan_dashboard, @restaurant)

    respond_to do |format|
      format.html { redirect_to restaurant_path(@restaurant), alert: 'Floorplan dashboard is not enabled for this restaurant.' }
      format.json { render json: { error: 'Feature not enabled' }, status: :service_unavailable }
    end
  end
end
