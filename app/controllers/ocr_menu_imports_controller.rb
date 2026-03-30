class OcrMenuImportsController < ApplicationController
  include Pundit::Authorization

  require 'sidekiq/api'

  skip_before_action :set_current_employee, only: %i[reorder_sections reorder_items]
  skip_before_action :set_permissions, only: %i[reorder_sections reorder_items]
  skip_before_action :redirect_to_onboarding_if_needed, only: %i[reorder_sections reorder_items]
  before_action :set_restaurant
  before_action :set_ocr_menu_import,
                only: %i[show edit update destroy process_pdf cancel_processing progress confirm_import reorder_sections reorder_items toggle_section_confirmation
                         toggle_all_confirmation polish polish_progress set_section_price]
  before_action :authorize_import,
                only: %i[show edit update destroy process_pdf progress confirm_import reorder_sections reorder_items toggle_section_confirmation
                         toggle_all_confirmation polish polish_progress set_section_price]

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
    render json: { ok: false, error: 'unable to update section' }, status: :unprocessable_content
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
    render json: { ok: false, error: 'unable to update all' }, status: :unprocessable_content
  end

  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/set_section_price
  def set_section_price
    section = @ocr_menu_import.ocr_menu_sections.find_by(id: params[:section_id])
    return render json: { ok: false, error: 'Section not found' }, status: :not_found unless section
    price = BigDecimal(params[:price].to_s)

    if price.negative?
      return render json: { ok: false, error: 'Price must be >= 0' }, status: :unprocessable_content
    end

    scope = section.ocr_menu_items
    scope = scope.where('price IS NULL OR price = 0') unless ActiveModel::Type::Boolean.new.cast(params[:override_all])

    updated = 0
    scope.find_each do |item|
      item.update!(
        price: price,
        metadata: (item.metadata || {}).merge('price_estimated' => false, 'price_source' => 'admin_section_override'),
      )
      updated += 1
    end

    render json: { ok: true, updated: updated, section_id: section.id, price: price.to_f }
  rescue ActiveRecord::RecordNotFound
    render json: { ok: false, error: 'Section not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("[OcrMenuImportsController#set_section_price] #{e.class}: #{e.message}")
    render json: { ok: false, error: e.message }, status: :unprocessable_content
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

  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id/progress
  def progress
    render json: @ocr_menu_import.progress_payload
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports/:id/polish
  def polish
    authorize @ocr_menu_import, :polish?

    total = @ocr_menu_import.ocr_menu_items.count
    jid = OcrMenuImportPolisherJob.perform_async(@ocr_menu_import.id)

    begin
      Sidekiq.redis do |r|
        r.setex("ocr_polish:#{jid}", 24 * 3600, {
          status: 'queued',
          current: 0,
          total: total,
          message: 'Queued AI polish',
          import_id: @ocr_menu_import.id,
        }.to_json,)
      end
    rescue StandardError => e
      Rails.logger.warn("[OcrMenuImportsController] Failed to init polish progress for #{jid}: #{e.message}")
    end

    respond_to do |format|
      format.html do
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import), notice: 'AI Polish has been queued.'
      end
      format.json do
        render json: { job_id: jid, total: total, status: 'queued' }
      end
    end
  end

  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id/polish_progress
  def polish_progress
    authorize @ocr_menu_import, :polish_progress?

    jid = params[:job_id].to_s
    payload = nil
    begin
      Sidekiq.redis do |r|
        json = r.get("ocr_polish:#{jid}")
        payload = json.present? ? JSON.parse(json) : {}
      end
    rescue StandardError => e
      Rails.logger.warn("[OcrMenuImportsController] Polish progress read failed for #{jid}: #{e.message}")
      payload ||= {}
    end

    payload ||= {}
    payload['job_id'] = jid
    payload['import_id'] ||= @ocr_menu_import.id

    render json: payload
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

  # POST /restaurants/:restaurant_id/ocr_menu_imports/import_from_menu_source
  def import_from_menu_source
    menu_source = MenuSource.find(params[:menu_source_id])

    unless menu_source.latest_file.attached?
      redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                  alert: 'Menu source has no file attached', status: :see_other
      return
    end

    import = @restaurant.ocr_menu_imports.new(
      name: menu_source.display_name,
      source_locale: '',
    )
    import.pdf_file.attach(menu_source.latest_file.blob)

    if import.save
      import.process_pdf_async
      redirect_to restaurant_ocr_menu_import_path(@restaurant, import),
                  notice: t('ocr_menu_imports.controller.queued')
    else
      redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                  alert: "Could not create import: #{import.errors.full_messages.join(', ')}", status: :see_other
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                alert: 'Menu source not found', status: :see_other
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports/import_from_web_menu_source
  def import_from_web_menu_source
    menu_source = MenuSource.find(params[:menu_source_id])

    unless menu_source.html? && menu_source.source_url.present?
      redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                  alert: 'Not a valid web menu source', status: :see_other
      return
    end

    import = @restaurant.ocr_menu_imports.create!(
      name: "Web menu – #{menu_source.display_name}",
      status: 'pending',
      metadata: {
        'source' => 'web_scrape',
        'menu_source_id' => menu_source.id,
        'phase' => 'queued',
      },
    )

    WebMenuSourceImportJob.perform_later(
      ocr_menu_import_id: import.id,
      menu_source_id: menu_source.id,
    )

    redirect_to restaurant_ocr_menu_import_path(@restaurant, import),
                notice: 'Web menu import queued — processing will begin shortly'
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                alert: 'Menu source not found', status: :see_other
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports
  def create
    @ocr_menu_import = @restaurant.ocr_menu_imports.new(ocr_menu_import_params)
    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)

    # AI guardrail: auto-set ai_mode based on restaurant claim status
    if @ocr_menu_import.ai_mode.blank? || !@ocr_menu_import.ai_mode_changed?
      @ocr_menu_import.ai_mode = @restaurant.unclaimed? ? :normalize_only : :full_enrich
    end

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
      render :new, status: :unprocessable_content
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
        format.html { render :edit, status: :unprocessable_content }
        format.json do
          render json: { ok: false, errors: @ocr_menu_import.errors.full_messages }, status: :unprocessable_content
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

  def cancel_processing
    authorize @ocr_menu_import, :cancel_processing?

    removed_jobs = remove_pending_processing_jobs(@ocr_menu_import.id)
    metadata = (@ocr_menu_import.metadata || {}).merge('cancel_requested' => true, 'cancel_requested_at' => Time.current.iso8601, 'phase' => 'cancelled')

    if @ocr_menu_import.respond_to?(:may_fail?) && @ocr_menu_import.may_fail?
      @ocr_menu_import.update!(metadata: metadata)
      @ocr_menu_import.fail!('Cancelled manually')
    else
      @ocr_menu_import.update!(metadata: metadata, error_message: 'Cancelled manually', failed_at: @ocr_menu_import.failed_at || Time.current)
    end

    redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                notice: "Import cancelled#{" (removed #{removed_jobs} queued job#{'s' unless removed_jobs == 1})" if removed_jobs.positive?}"
  end

  # POST /restaurants/:restaurant_id/ocr_menu_imports/:id/confirm_import
  def confirm_import
    unless @ocr_menu_import.completed?
      return redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                         alert: t('ocr_menu_imports.controller.confirm_section')
    end

    # Auto-confirm all sections/items if none are confirmed yet (backwards compat)
    if @ocr_menu_import.ocr_menu_sections.confirmed.none? && @ocr_menu_import.ocr_menu_sections.any?
      @ocr_menu_import.ocr_menu_sections.update_all(is_confirmed: true)
      @ocr_menu_import.ocr_menu_sections.each { |s| s.ocr_menu_items.update_all(is_confirmed: true) }
    end

    begin
      service = ImportToMenu.new(restaurant: @restaurant, import: @ocr_menu_import)
      if @ocr_menu_import.menu_id.present?
        # Republish into existing menu: update existing and add new confirmed content
        sync = ActiveModel::Type::Boolean.new.cast(params[:sync])
        _, stats = service.upsert_into_menu(@ocr_menu_import.menu, sync: sync)
        notice = t('ocr_menu_imports.controller.republished')
        if stats.present?
          notice << " (sections: +#{stats[:sections_created]}/~#{stats[:sections_updated]}#{", -#{stats[:sections_archived]}" if sync}, items: +#{stats[:items_created]}/~#{stats[:items_updated]}#{", -#{stats[:items_archived]}" if sync})"
        end
        redirect_to edit_restaurant_path(@restaurant, section: 'menus'), notice: notice, status: :see_other
      else
        # First-time publish: create a new menu from confirmed content
        service.call
        redirect_to edit_restaurant_path(@restaurant, section: 'menus'), notice: t('ocr_menu_imports.controller.published'), status: :see_other
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
                    status: :unprocessable_content,)
    end

    OcrMenuSection.transaction do
      section_ids.each_with_index do |sid, idx|
        section = @ocr_menu_import.ocr_menu_sections.find_by(id: sid)
        return render(json: { error: 'section not found' }, status: :unprocessable_content) unless section

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
    return render(json: { error: 'section not found' }, status: :unprocessable_content) unless section

    # Ensure all items belong to this section for safety
    items = section.ocr_menu_items.where(id: item_ids)
    Rails.logger.warn("[reorder_items] found #{items.size} matching items for ids #{item_ids.inspect} (expected #{item_ids.size}) in section #{section.id}")
    return render(json: { error: 'items mismatch' }, status: :unprocessable_content) if items.size != item_ids.size

    OcrMenuItem.transaction do
      item_ids.each_with_index do |iid, idx|
        item = section.ocr_menu_items.find_by(id: iid)
        return head :unprocessable_content unless item

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

  # DELETE /restaurants/:restaurant_id/ocr_menu_imports/bulk_destroy
  def bulk_destroy
    imports = policy_scope(OcrMenuImport).where(restaurant_id: @restaurant.id)
    ids = Array(params[:ocr_menu_import_ids]).map(&:to_s).compact_blank

    if ids.any?
      to_destroy = imports.where(id: ids)
      to_destroy.find_each do |import|
        authorize import, :destroy?
        import.destroy
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/import_2025',
          locals: { restaurant: @restaurant },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'import'),
                    notice: t('ocr_menu_imports.controller.deleted')
      end
    end
  end

  private

  def remove_pending_processing_jobs(import_id)
    removed = 0

    [Sidekiq::Queue.new('default'), Sidekiq::RetrySet.new, Sidekiq::ScheduledSet.new].each do |set|
      set.each do |job|
        payload = job.item
        wrapped = payload['wrapped']
        args = payload['args']
        active_job_payload = args.is_a?(Array) ? args.last : nil
        job_args = active_job_payload.is_a?(Hash) ? active_job_payload['arguments'] : nil
        matches = (wrapped == 'PdfMenuExtractionJob' && [[import_id], [import_id.to_s]].include?(job_args)) ||
                  (payload['class'] == 'PdfMenuExtractionJob' && [[import_id], [import_id.to_s]].include?(args))
        next unless matches

        job.delete
        removed += 1
      end
    end

    removed
  rescue StandardError => e
    Rails.logger.warn("[OcrMenuImportsController] Failed to remove pending OCR jobs for import ##{import_id}: #{e.class}: #{e.message}")
    0
  end

  def set_restaurant
    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
    unless @restaurant
      respond_to do |format|
        format.json { render json: { error: { code: 'not_found', message: 'Restaurant not found' } }, status: :not_found }
        format.html { redirect_to root_path, alert: 'Restaurant not found' }
      end
      return
    end
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
