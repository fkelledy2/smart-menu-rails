class TaxesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax, only: %i[show edit update destroy]
  before_action :return_url

  skip_around_action :switch_locale, only: %i[reorder bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index reorder bulk_update]
  after_action :verify_policy_scoped, only: [:index]

  # GET /taxes or /taxes.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @taxes = policy_scope(Tax).where(restaurant: @futureParentRestaurant, archived: false).where.not(status: :archived)
    else
      @taxes = policy_scope(Tax).where(archived: false).where.not(status: :archived)
    end
  end

  # GET /taxes/1 or /taxes/1.json
  def show
    authorize @tax
  end

  # GET /taxes/new
  def new
    if current_user
      @tax = Tax.new
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tax.restaurant = @futureParentRestaurant
      end
      authorize @tax
    else
      redirect_to root_url
    end
  end

  # GET /taxes/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /taxes or /taxes.json
  def create
    if current_user
      @tax = Tax.new(tax_params)
      authorize @tax
      respond_to do |format|
        if @tax.save
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace('taxes_new_tax', ''),
              turbo_stream.replace(
                'restaurant_content',
                partial: 'restaurants/sections/catalog_2025',
                locals: { restaurant: @tax.restaurant, filter: 'all' }
              )
            ]
          end
          format.html do
            redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.created')
          end
          # format.html { redirect_to @return_url, notice: "Tax was successfully created." }
          format.json { render :show, status: :created, location: @tax }
        else
          format.turbo_stream { render :new, status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @tax.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # PATCH/PUT /taxes/1 or /taxes/1.json
  def update
    if current_user
      respond_to do |format|
        if @tax.update(tax_params)
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace('taxes_edit_tax', ''),
              turbo_stream.replace(
                'restaurant_content',
                partial: 'restaurants/sections/catalog_2025',
                locals: { restaurant: @tax.restaurant, filter: 'all' }
              )
            ]
          end
          format.html do
            redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.updated')
          end
          # format.html { redirect_to tax_url(@tax), notice: "Tax was successfully updated." }
          format.json { render :show, status: :ok, location: @tax }
        else
          format.turbo_stream { render :edit, status: :unprocessable_entity }
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tax.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # DELETE /taxes/1 or /taxes/1.json
  def destroy
    authorize @tax

    @tax.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.deleted')
      end
      format.json { head :no_content }
    end
  end

  # PATCH /restaurants/:restaurant_id/taxes/bulk_update
  def bulk_update
    restaurant = Restaurant.find(params[:restaurant_id])
    taxes = policy_scope(Tax).where(restaurant_id: restaurant.id, archived: false)

    ids = Array(params[:tax_ids]).map(&:to_s).reject(&:blank?)
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/catalog_2025',
            locals: { restaurant: restaurant, filter: 'all' }
          )
        end
        format.html do
          redirect_to edit_restaurant_path(restaurant, section: 'taxes_and_tips')
        end
      end
      return
    end

    to_update = taxes.where(id: ids)
    to_update.find_each do |tax|
      authorize tax, :update?
      tax.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/catalog_2025',
          locals: { restaurant: restaurant, filter: 'all' }
        )
      end
      format.html do
        redirect_to edit_restaurant_path(restaurant, section: 'taxes_and_tips')
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/taxes/reorder
  def reorder
    restaurant = Restaurant.find(params[:restaurant_id])
    taxes = policy_scope(Tax).where(restaurant_id: restaurant.id, archived: false)

    order = params[:order]
    unless order.is_a?(Array)
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_entity
    end

    Tax.transaction do
      order.each do |item|
        item_hash = if item.is_a?(ActionController::Parameters)
          item.to_unsafe_h
        elsif item.is_a?(Hash)
          item
        else
          next
        end

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        next if id.blank? || seq.nil?

        tax = taxes.find(id)
        authorize tax, :update?
        tax.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Taxes reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Tax not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Taxes reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
  end

  private

  def return_url
    @return_url = url_from(params[:return_to]) || @tax
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_tax
    @tax = Tax.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tax_params
    params.require(:tax).permit(:name, :taxtype, :taxpercentage, :sequence, :status, :restaurant_id)
  end
end
