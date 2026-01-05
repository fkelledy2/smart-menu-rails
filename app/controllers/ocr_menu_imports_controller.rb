class OcrMenuImportsController < ApplicationController
  include Pundit::Authorization

  skip_before_action :set_current_employee, only: %i[reorder_sections reorder_items]
  skip_before_action :set_permissions, only: %i[reorder_sections reorder_items]
  skip_before_action :redirect_to_onboarding_if_needed, only: %i[reorder_sections reorder_items]
  skip_forgery_protection only: %i[reorder_sections reorder_items]
  before_action :set_restaurant
  before_action :set_ocr_menu_import,
                only: %i[show edit update destroy process_pdf confirm_import reorder_sections reorder_items toggle_section_confirmation
                         toggle_all_confirmation]
  before_action :authorize_import,
                only: %i[show edit update destroy process_pdf confirm_import reorder_sections reorder_items toggle_section_confirmation
                         toggle_all_confirmation]

  # GET /restaurants/:restaurant_id/ocr_menu_imports
  def index
    @ocr_menu_imports = @restaurant.ocr_menu_imports.recent
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
  end

  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/toggle_section_confirmation
  def toggle_section_confirmation
    section_id = params[:section_id].to_i
    confirmed = ActiveModel::Type::Boolean.new.cast(params[:confirmed])
    section = @ocr_menu_import.ocr_menu_sections.find_by(id: section_id)
    return render json: { ok: false, error: 'section not found' }, status: :not_found unless section

    OcrMenuSection.transaction do
      section.update!(is_confirmed: confirmed)
      section.ocr_menu_items.update_all(is_confirmed: confirmed)
    end

    render json: { ok: true, section_id: section.id, confirmed: confirmed }
  rescue StandardError => e
    Rails.logger.error("toggle_section_confirmation error: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'unable to update section' }, status: :unprocessable_entity
  end

  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/toggle_all_confirmation
  def toggle_all_confirmation
    confirmed = ActiveModel::Type::Boolean.new.cast(params[:confirmed])
    OcrMenuSection.transaction do
      @ocr_menu_import.ocr_menu_sections.update_all(is_confirmed: confirmed)
      @ocr_menu_import.ocr_menu_items.update_all(is_confirmed: confirmed)
    end
    render json: { ok: true, confirmed: confirmed }
  rescue StandardError => e
    Rails.logger.error("toggle_all_confirmation error: #{e.class}: #{e.message}")
    render json: { ok: false, error: 'unable to update all' }, status: :unprocessable_entity
  end

  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id
  def show
    @ocr_menu_sections = @ocr_menu_import.ocr_menu_sections.ordered.includes(:ocr_menu_items)
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)

    respond_to do |format|
      format.html
      format.json { render json: @ocr_menu_import }
    end
  end

  # GET /restaurants/:restaurant_id/ocr_menu_imports/new
  def new
    @ocr_menu_import = @restaurant.ocr_menu_imports.new
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
  end

  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id/edit
  def edit
    @ocr_menu_sections = @ocr_menu_import.ocr_menu_sections.ordered.includes(:ocr_menu_items)
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports
  def create
    @ocr_menu_import = @restaurant.ocr_menu_imports.new(ocr_menu_import_params)
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)

    if @ocr_menu_import.save
      if @ocr_menu_import.pdf_file.attached?
        @ocr_menu_import.process_pdf_async
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                    notice: t('ocr_menu_imports.controller.queued')
      else
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                    alert: t('ocr_menu_imports.controller.attach_pdf')
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/ocr_menu_imports/:id
  def update
    if @ocr_menu_import.update(ocr_menu_import_params)
      respond_to do |format|
        format.html do
          redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                      notice: t('ocr_menu_imports.controller.updated')
        end
        format.json do
          render json: { ok: true, import: { id: @ocr_menu_import.id, name: @ocr_menu_import.name } }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: { ok: false, errors: @ocr_menu_import.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports/:id/process_pdf
  def process_pdf
    if @ocr_menu_import.may_process?
      # Move to processing immediately for instant UI feedback
      begin
        @ocr_menu_import.process!
      rescue AASM::InvalidTransition => e
        Rails.logger.warn "process_pdf: InvalidTransition for OcrMenuImport ##{@ocr_menu_import.id}: #{e.message}"
      end
      @ocr_menu_import.process_pdf_async
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                  notice: t('ocr_menu_imports.controller.processing_restarted')
    else
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                  alert: t('ocr_menu_imports.controller.unable_restart', status: @ocr_menu_import.status)
    end
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports/:id/confirm_import
  def confirm_import
    unless @ocr_menu_import.completed? && @ocr_menu_import.ocr_menu_sections.confirmed.any?
      return redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                         alert: t('ocr_menu_imports.controller.confirm_section')
    end

    begin
      service = ImportToMenu.new(restaurant: @restaurant, import: @ocr_menu_import)
      if @ocr_menu_import.menu_id.present?
        # Republish into existing menu: update existing and add new confirmed content
        sync = ActiveModel::Type::Boolean.new.cast(params[:sync])
        menu, stats = service.upsert_into_menu(@ocr_menu_import.menu, sync: sync)
        notice = t('ocr_menu_imports.controller.republished')
        if stats.present?
          notice << " (sections: +#{stats[:sections_created]}/~#{stats[:sections_updated]}#{", -#{stats[:sections_archived]}" if sync}, items: +#{stats[:items_created]}/~#{stats[:items_updated]}#{", -#{stats[:items_archived]}" if sync})"
        end
        redirect_to edit_restaurant_menu_path(@restaurant, menu), notice: notice
      else
        # First-time publish: create a new menu from confirmed content
        menu = service.call
        redirect_to edit_restaurant_menu_path(@restaurant, menu), notice: t('ocr_menu_imports.controller.published')
      end
    rescue StandardError => e
      Rails.logger.error("Error creating menu from import ##{@ocr_menu_import.id}: #{e.class}: #{e.message}")
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                  alert: t('ocr_menu_imports.controller.fail_create', error: e.message)
    end
  end

  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/reorder_sections
  def reorder_sections
    unless current_user && @ocr_menu_import.restaurant.user_id == current_user.id
      return render(
        json: { error: { code: 'forbidden',
                         message: t('ocr_menu_imports.controller.unauthorized',
                                    default: 'Unauthorized',), } }, status: :forbidden,
      )
    end

    section_ids = Array(params[:section_ids]).compact_blank.map(&:to_i)
    Rails.logger.warn("[reorder_sections] raw=#{params[:section_ids].inspect} parsed=#{section_ids.inspect}")
    return render(json: { error: 'section_ids required' }, status: :bad_request) if section_ids.blank?

    # Ensure all sections belong to this import for safety and in given order
    sections = @ocr_menu_import.ocr_menu_sections.where(id: section_ids)
    Rails.logger.warn("[reorder_sections] found #{sections.size} matching sections for ids #{section_ids.inspect} (expected #{section_ids.size})")
    if sections.size != section_ids.size
      return render(json: { error: 'sections mismatch' },
                    status: :unprocessable_entity,)
    end

    OcrMenuSection.transaction do
      section_ids.each_with_index do |sid, idx|
        section = @ocr_menu_import.ocr_menu_sections.find_by(id: sid)
        return render(json: { error: 'section not found' }, status: :unprocessable_entity) unless section

        Rails.logger.warn("[reorder_sections] updating section ##{sid} -> sequence #{idx + 1}")
        section.update!(sequence: idx + 1)
      end
    end

    render json: { ok: true, section_ids: section_ids }
  end

  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/reorder_items
  # Params: section_id: Integer, item_ids: [Integer]
  def reorder_items
    unless current_user && @ocr_menu_import.restaurant.user_id == current_user.id
      return render(
        json: { error: { code: 'forbidden',
                         message: t('ocr_menu_imports.controller.unauthorized',
                                    default: 'Unauthorized',), } }, status: :forbidden,
      )
    end

    section_id = params[:section_id].to_i
    item_ids = Array(params[:item_ids]).compact_blank.map(&:to_i)
    Rails.logger.warn("[reorder_items] section_id raw=#{params[:section_id].inspect} parsed=#{section_id} item_ids raw=#{params[:item_ids].inspect} parsed=#{item_ids.inspect}")
    if section_id.zero? || item_ids.blank?
      return render(json: { error: 'section_id and item_ids required' },
                    status: :bad_request,)
    end

    # Ensure section belongs to this import
    section = @ocr_menu_import.ocr_menu_sections.find_by(id: section_id)
    return render(json: { error: 'section not found' }, status: :unprocessable_entity) unless section

    # Ensure all items belong to this section for safety
    items = section.ocr_menu_items.where(id: item_ids)
    Rails.logger.warn("[reorder_items] found #{items.size} matching items for ids #{item_ids.inspect} (expected #{item_ids.size}) in section #{section.id}")
    return render(json: { error: 'items mismatch' }, status: :unprocessable_entity) if items.size != item_ids.size

    OcrMenuItem.transaction do
      item_ids.each_with_index do |iid, idx|
        item = section.ocr_menu_items.find_by(id: iid)
        return head :unprocessable_entity unless item

        Rails.logger.warn("[reorder_items] updating item ##{iid} -> sequence #{idx + 1}")
        item.update!(sequence: idx + 1)
      end
    end

    render json: { ok: true, section_id: section.id, item_ids: item_ids }
  end

  # DELETE /restaurants/:restaurant_id/ocr_menu_imports/:id
  def destroy
    @ocr_menu_import.destroy
    redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                notice: t('ocr_menu_imports.controller.deleted')
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
    authorize @restaurant, :show?
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.json do
        render json: { error: { code: 'forbidden', message: 'Unauthorized access to restaurant' } },
               status: :forbidden
      end
      format.html { redirect_to root_path, alert: 'Unauthorized access to restaurant' }
      format.any { head :forbidden }
    end
  end

  def set_ocr_menu_import
    @ocr_menu_import = @restaurant.ocr_menu_imports.find(params[:id])
  end

  def ocr_menu_import_params
    params.require(:ocr_menu_import).permit(:name, :pdf_file, :source_locale)
  end

  def authorize_import
    authorize @ocr_menu_import
  rescue Pundit::NotAuthorizedError
    respond_to do |format|
      format.json do
        render json: { error: { code: 'forbidden', message: t('ocr_menu_imports.controller.unauthorized', default: 'Unauthorized') } },
               status: :forbidden
      end
      format.html { redirect_to root_path, alert: t('ocr_menu_imports.controller.unauthorized') }
      format.any  { head :forbidden }
    end
  end
end
