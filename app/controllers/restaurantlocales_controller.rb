class RestaurantlocalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurantlocale, only: %i[show edit update destroy]

  skip_around_action :switch_locale, only: %i[reorder bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index reorder bulk_update]
  after_action :verify_policy_scoped, only: [:index]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    if params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @restaurantlocales = policy_scope(Restaurantlocale).where(restaurant_id: @restaurant.id).order(:sequence)
    else
      @restaurantlocales = policy_scope(Restaurantlocale).where(archived: false).order(:sequence)
    end
  end

  # GET	/restaurants/:restaurant_id/restaurantlocales/:menu_id/tablesettings/:id(.:format)	restaurantlocales#show
  # GET	/restaurants/:restaurant_id/restaurantlocales/:id(.:format)	 restaurantlocales#show
  # GET /restaurantlocales/1 or /restaurantlocales/1.json
  def show
    authorize @restaurantlocale
  end

  # GET /menus/new
  def new
    @restaurantlocale = Restaurantlocale.new
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      @restaurantlocale.restaurant = @restaurant
    end
    authorize @restaurantlocale
  end

  # GET /restaurantlocales/1/edit
  def edit
    @restaurant = @restaurantlocale.restaurant
    authorize @restaurantlocale
  end

  # POST /restaurantlocales or /restaurantlocales.json
  def create
    @restaurantlocale = Restaurantlocale.new(restaurantlocale_params)
    authorize @restaurantlocale

    plan = current_user&.plan
    languages_limit = plan&.languages
    if languages_limit.present? && languages_limit != -1
      context_restaurant = @restaurantlocale.restaurant || Restaurant.find_by(id: params.dig(:restaurantlocale, :restaurant_id))
      if context_restaurant
        existing_count = Restaurantlocale.where(restaurant_id: context_restaurant.id)
          .where.not(status: Restaurantlocale.statuses[:archived])
          .count

        if existing_count >= languages_limit
          @restaurantlocale.errors.add(:base, 'Your plan limit has been reached for number of languages')
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                'localization_new_locale',
                ApplicationController.render(
                  partial: 'restaurantlocales/form',
                  assigns: { restaurantlocale: @restaurantlocale },
                  formats: [:html],
                ),
              ), status: :unprocessable_content
            end
            format.html do
              redirect_to edit_restaurant_path(id: context_restaurant.id), alert: @restaurantlocale.errors.full_messages.to_sentence
            end
            format.json { render json: { errors: @restaurantlocale.errors.full_messages }, status: :unprocessable_content }
          end
          return
        end
      end
    end

    respond_to do |format|
      if @restaurantlocale.save
        if @restaurantlocale.dfault == true
          Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).find_each do |rl|
            if rl.id != @restaurantlocale.id
              rl.dfault = false
              rl.save
            end
          end
        end
        MenuLocalizationJob.perform_async(@restaurantlocale.id)
        format.turbo_stream do
          @restaurant = @restaurantlocale.restaurant
          render turbo_stream: [
            turbo_stream.replace('localization_new_locale', ''),
            turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/localization_2025', locals: { restaurant: @restaurant, filter: 'all' }),
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.created')
        end
        format.json { render :show, status: :created, location: @restaurantlocale }
      else
        format.turbo_stream do
          @restaurant = @restaurantlocale.restaurant || Restaurant.find_by(id: params.dig(:restaurantlocale, :restaurant_id))
          render turbo_stream: turbo_stream.replace(
            'localization_new_locale',
            ApplicationController.render(
              partial: 'restaurantlocales/form',
              assigns: { restaurantlocale: @restaurantlocale },
              formats: [:html],
            ),
          ), status: :unprocessable_content
        end
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @menu.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /restaurantlocales/1 or / restaurantlocales/1.json
  def update
    authorize @restaurantlocale
    respond_to do |format|
      Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).find_each do |rl|
        if rl.id != @restaurantlocale.id
          rl.dfault = false
          rl.save
        end
      end
      if @restaurantlocale.update(restaurantlocale_params)
        format.turbo_stream do
          @restaurant = @restaurantlocale.restaurant
          render turbo_stream: [
            turbo_stream.replace('localization_edit_locale', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/localization_2025',
              locals: { restaurant: @restaurant, filter: 'all' },
            ),
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.updated')
        end
        format.json { render :show, status: :ok, location: @restaurantlocale }
      else
        format.turbo_stream { render :edit, status: :unprocessable_content }
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @menu.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /restaurantlocales/1 or /restaurantlocales/1.json
  def destroy
    authorize @restaurantlocale

    if @restaurantlocale.inactive?
      @restaurantlocale.destroy!
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.deleted')
        end
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.active_not_deleted')
        end
        format.json { head :no_content }
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/restaurantlocales/bulk_update
  def bulk_update
    @restaurant = Restaurant.find(params[:restaurant_id])
    restaurantlocales = policy_scope(Restaurantlocale).where(restaurant_id: @restaurant.id)

    ids = Array(params[:restaurantlocale_ids]).map(&:to_s).compact_blank
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/localization_2025',
            locals: { restaurant: @restaurant, filter: 'all' },
          )
        end
        format.html do
          redirect_to edit_restaurant_path(@restaurant, section: 'localization')
        end
      end
      return
    end

    to_update = restaurantlocales.where(id: ids)
    to_update.find_each do |rl|
      authorize rl, :update?
      next if rl.respond_to?(:dfault) && rl.dfault

      rl.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/localization_2025',
          locals: { restaurant: @restaurant, filter: 'all' },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'localization'),
                    notice: t('restaurantlocales.controller.updated')
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/restaurantlocales/reorder
  def reorder
    @restaurant = Restaurant.find(params[:restaurant_id])
    restaurantlocales = policy_scope(Restaurantlocale).where(restaurant_id: @restaurant.id)

    order = params[:order]
    $stdout.sync = true
    Rails.logger.debug { "[Restaurantlocales#reorder] hit pid=#{Process.pid} env=#{Rails.env} restaurant_id=#{@restaurant.id} order_class=#{order.class} order=#{order.inspect}" }
    Rails.logger.info(
      "Restaurantlocales#reorder hit restaurant_id=#{@restaurant.id} order_class=#{order.class} order=#{order.inspect}",
    )
    unless order.is_a?(Array)
      Rails.logger.warn(
        "Restaurantlocales#reorder invalid payload restaurant_id=#{@restaurant.id} order=#{order.inspect}",
      )
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_content
    end

    Restaurantlocale.transaction do
      order.each do |item|
        item_hash = if item.is_a?(ActionController::Parameters)
                      item.to_unsafe_h
                    elsif item.is_a?(Hash)
                      item
                    else
                      Rails.logger.debug { "[Restaurantlocales#reorder] skipping non-hash item pid=#{Process.pid} item_class=#{item.class} item=#{item.inspect}" }
                      Rails.logger.warn("Restaurantlocales#reorder skipping non-hash item item_class=#{item.class} item=#{item.inspect}")
                      next
                    end

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        if id.blank? || seq.nil?
          Rails.logger.debug { "[Restaurantlocales#reorder] skipping invalid item pid=#{Process.pid} item=#{item_hash.inspect}" }
          Rails.logger.warn("Restaurantlocales#reorder skipping invalid item item=#{item_hash.inspect}")
          next
        end

        rl = restaurantlocales.find(id)
        authorize rl, :update?
        old_seq = rl.sequence
        new_seq = seq.to_i
        rl.update_column(:sequence, new_seq)
        Rails.logger.debug { "[Restaurantlocales#reorder] updated pid=#{Process.pid} restaurantlocale_id=#{rl.id} old_sequence=#{old_seq.inspect} new_sequence=#{new_seq}" }
        Rails.logger.info(
          "Restaurantlocales#reorder updated restaurantlocale_id=#{rl.id} old_sequence=#{old_seq.inspect} new_sequence=#{new_seq}",
        )
      end
    end

    response_body = { status: 'success', message: 'Languages reordered successfully' }
    if Rails.env.development?
      db_config = ActiveRecord::Base.connection_db_config
      response_body[:debug] = {
        pid: Process.pid,
        env: Rails.env,
        database: db_config&.database,
        host: db_config&.host,
        adapter: db_config&.adapter,
      }
    end

    render json: response_body, status: :ok
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn(
      "Restaurantlocales#reorder record not found restaurant_id=#{params[:restaurant_id]} order=#{params[:order].inspect}",
    )
    render json: { status: 'error', message: 'Language not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Restaurantlocales reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_content
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurantlocale
    @restaurantlocale = Restaurantlocale.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def restaurantlocale_params
    params.require(:restaurantlocale).permit(:locale, :status, :dfault, :restaurant_id)
  end
end
