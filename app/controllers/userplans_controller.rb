class UserplansController < ApplicationController
  require 'stripe'

  before_action :authenticate_user!
  before_action :set_userplan, only: %i[show edit update destroy stripe_success start_plan_change portal_plan_changed]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /userplans or /userplans.json
  def index
    @userplans = policy_scope(Userplan).limit(100) # Use limit for memory safety, since pagination gem is not installed
  end

  # GET /userplans/1 or /userplans/1.json
  def show
    authorize @userplan
  end

  # GET /userplans/new
  def new
    @userplan = Userplan.new
    authorize @userplan
  end

  # GET /userplans/1/edit
  def edit
    authorize @userplan
    @plans = Plan.display_order
  end

  def start_plan_change
    authorize @userplan

    restaurant = current_user.restaurants.order(:id).first
    unless restaurant
      return redirect_to edit_userplan_path(@userplan), alert: 'No restaurant found for billing'
    end

    sub = restaurant.restaurant_subscription
    unless sub&.stripe_customer_id.present? && sub&.stripe_subscription_id.present?
      return redirect_to edit_userplan_path(@userplan), alert: 'Billing is not configured for this restaurant'
    end

    plan = Plan.find_by(id: params[:plan_id])
    unless plan
      return redirect_to edit_userplan_path(@userplan), alert: 'Plan not found'
    end

    guard = guard_plan_downgrade!(plan)
    if guard[:blocked]
      return redirect_to edit_userplan_path(@userplan), alert: guard[:message]
    end

    ensure_stripe_api_key!

    price_id = stripe_price_id_for_plan(plan, interval: 'month')
    if price_id.blank?
      return redirect_to edit_userplan_path(@userplan), alert: 'Selected plan is not configured for billing'
    end

    subscription = Stripe::Subscription.retrieve({ id: sub.stripe_subscription_id.to_s })
    subscription_item_id = Array(subscription.items&.data).first&.id.to_s
    if subscription_item_id.blank?
      return redirect_to edit_userplan_path(@userplan), alert: 'Billing is not configured for this restaurant'
    end

    session = Stripe::BillingPortal::Session.create(
      customer: sub.stripe_customer_id.to_s,
      return_url: edit_userplan_url(@userplan),
      flow_data: {
        type: 'subscription_update_confirm',
        subscription_update_confirm: {
          subscription: sub.stripe_subscription_id.to_s,
          items: [
            {
              id: subscription_item_id,
              price: price_id.to_s,
            },
          ],
        },
        after_completion: {
          type: 'redirect',
          redirect: {
            return_url: portal_plan_changed_userplan_url(@userplan, plan_id: plan.id),
          },
        },
      },
    )

    redirect_to session.url.to_s, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.warn(
      "[UserplansController#start_plan_change] stripe_error=#{e.class} message=#{e.message} user_id=#{current_user.id} userplan_id=#{@userplan.id} restaurant_id=#{restaurant&.id} subscription_id=#{sub&.stripe_subscription_id} plan_id=#{params[:plan_id]}",
    )

    msg = e.message.to_s
    if msg.include?('subscription update feature') && msg.include?('portal configuration')
      msg = 'Plan changes are disabled in Stripe Customer Portal settings. Enable Subscription update in the Stripe Dashboard (Customer portal configuration), then try again.'
    end

    redirect_to edit_userplan_path(@userplan), alert: "Failed to start plan change: #{msg}"
  rescue StandardError => e
    Rails.logger.warn(
      "[UserplansController#start_plan_change] failed=#{e.class} message=#{e.message} user_id=#{current_user.id} userplan_id=#{@userplan.id} plan_id=#{params[:plan_id]}",
    )
    redirect_to edit_userplan_path(@userplan), alert: "Failed to start plan change: #{e.message}"
  end

  def portal_plan_changed
    authorize @userplan

    plan = Plan.find_by(id: params[:plan_id])
    unless plan
      return redirect_to edit_userplan_path(@userplan), alert: 'Plan not found'
    end

    restaurant = current_user.restaurants.order(:id).first
    unless restaurant
      return redirect_to edit_userplan_path(@userplan), alert: 'No restaurant found for billing'
    end

    sub = restaurant.restaurant_subscription
    unless sub&.stripe_subscription_id.present?
      return redirect_to edit_userplan_path(@userplan), alert: 'Billing is not configured for this restaurant'
    end

    guard = guard_plan_downgrade!(plan)
    if guard[:blocked]
      return redirect_to edit_userplan_path(@userplan), alert: guard[:message]
    end

    ensure_stripe_api_key!

    subscription = Stripe::Subscription.retrieve({ id: sub.stripe_subscription_id.to_s, expand: ['items.data.price'] })
    current_price_ids = Array(subscription.items&.data).map { |i| i.price&.id.to_s }.reject(&:blank?)

    expected_price_ids = [
      plan.respond_to?(:stripe_price_id_month) ? plan.stripe_price_id_month.to_s : '',
      plan.respond_to?(:stripe_price_id_year) ? plan.stripe_price_id_year.to_s : '',
    ].reject(&:blank?)

    unless (current_price_ids & expected_price_ids).any?
      return redirect_to edit_userplan_path(@userplan), alert: 'Subscription was not updated to the selected plan'
    end

    @userplan.update!(plan: plan)
    current_user.update!(plan: plan)

    redirect_to edit_userplan_path(@userplan), notice: t('common.flash.updated', resource: t('activerecord.models.userplan'))
  rescue StandardError => e
    Rails.logger.warn("[UserplansController#portal_plan_changed] failed: #{e.class}: #{e.message}")
    redirect_to edit_userplan_path(@userplan), alert: 'Failed to confirm plan change'
  end

  def stripe_success
    authorize @userplan

    ensure_stripe_api_key!
    session_id = params[:checkout_session_id].to_s
    if session_id.blank?
      return redirect_to edit_userplan_path(@userplan), alert: 'Missing checkout session'
    end

    session = Stripe::Checkout::Session.retrieve({ id: session_id, expand: ['subscription'] })
    metadata = session.respond_to?(:metadata) ? session.metadata : {}

    if metadata.respond_to?(:[]) && metadata['user_id'].to_s.present? && metadata['user_id'].to_s != current_user.id.to_s
      return head :forbidden
    end

    plan_id = metadata.respond_to?(:[]) ? metadata['plan_id'].to_s : ''
    plan = Plan.find_by(id: plan_id)
    unless plan
      return redirect_to edit_userplan_path(@userplan), alert: 'Plan not found for checkout session'
    end

    @userplan.update!(plan: plan)
    current_user.update!(plan: plan)

    redirect_to edit_userplan_path(@userplan), notice: t('common.flash.updated', resource: t('activerecord.models.userplan'))
  rescue StandardError => e
    Rails.logger.warn("[UserplansController#stripe_success] failed: #{e.class}: #{e.message}")
    redirect_to edit_userplan_path(@userplan), alert: 'Failed to confirm subscription'
  end

  # POST /userplans or /userplans.json
  def create
    @userplan = Userplan.new(userplan_params)
    authorize @userplan

    respond_to do |format|
      if @userplan.save
        @user = User.where(id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html do
          redirect_to root_path, notice: t('common.flash.created', resource: t('activerecord.models.userplan'))
        end
        format.json { render :show, status: :created, location: @userplan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /userplans/1 or /userplans/1.json
  def update
    authorize @userplan

    respond_to do |format|
      if @userplan.update(userplan_params)
        @user = User.where(id: @userplan.user.id).first
        @user.plan = @userplan.plan
        @user.save
        format.html do
          redirect_to edit_userplan_path(@userplan),
                      notice: t('common.flash.updated', resource: t('activerecord.models.userplan'))
        end
        format.json { render :show, status: :ok, location: @userplan }
      else
        @plans = Plan.display_order
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @userplan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /userplans/1 or /userplans/1.json
  def destroy
    authorize @userplan
    @userplan.destroy!

    respond_to do |format|
      format.html do
        redirect_to userplans_path, status: :see_other,
                                    notice: t('common.flash.deleted', resource: t('activerecord.models.userplan'))
      end
      format.json { head :no_content }
    end
  end

  private

  def guard_plan_downgrade!(target_plan)
    blocked = false
    parts = []

    active_restaurants_count = current_user.restaurants.where(archived: false, status: :active).count
    if target_plan.respond_to?(:locations) && target_plan.locations.to_i != -1 && active_restaurants_count > target_plan.locations.to_i
      blocked = true
      parts << "You have #{active_restaurants_count} active restaurants, but the selected plan allows #{target_plan.locations}"
    end

    if target_plan.respond_to?(:menusperlocation) && target_plan.menusperlocation.to_i != -1
      limit = target_plan.menusperlocation.to_i
      max_active_menus = current_user.restaurants.where(archived: false).map do |r|
        r.restaurant_menus
          .joins(:menu)
          .where(menus: { archived: false })
          .where(status: RestaurantMenu.statuses[:active])
          .count
      end.max.to_i

      if max_active_menus > limit
        blocked = true
        parts << "At least one restaurant has #{max_active_menus} active menus, but the selected plan allows #{limit} per restaurant"
      end
    end

    message = if blocked
      parts.join('. ') + '. Deactivate restaurants/menus first, then try again.'
    else
      ''
    end

    { blocked: blocked, message: message }
  end

  def stripe_price_id_for_plan(plan, interval: 'month')
    if interval == 'year'
      plan.respond_to?(:stripe_price_id_year) ? plan.stripe_price_id_year : nil
    else
      plan.respond_to?(:stripe_price_id_month) ? plan.stripe_price_id_month : nil
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_userplan
    @userplan = Userplan.find(params[:id])
    @plans = Plan.display_order
  end

  def ensure_stripe_api_key!
    return if Stripe.api_key.present?

    env_key = ENV['STRIPE_SECRET_KEY'].presence

    credentials_key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError
      nil
    end

    if credentials_key.blank?
      credentials_key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError
        nil
      end
    end

    key = if Rails.env.production?
      env_key || credentials_key
    else
      credentials_key.presence || env_key
    end

    raise 'Stripe is not configured' if key.blank?

    Stripe.api_key = key
  end

  # Only allow a list of trusted parameters through.
  def userplan_params
    params.require(:userplan).permit(:user_id, :plan_id)
  end
end
