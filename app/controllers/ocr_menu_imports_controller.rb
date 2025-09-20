class OcrMenuImportsController < ApplicationController
  skip_before_action :set_current_employee, only: [:reorder_sections, :reorder_items]
  skip_before_action :set_permissions, only: [:reorder_sections, :reorder_items]
  skip_forgery_protection only: [:reorder_sections, :reorder_items]
  before_action :set_restaurant
  before_action :set_ocr_menu_import, only: [:show, :edit, :update, :destroy, :process_pdf, :confirm_import, :reorder_sections, :reorder_items]
  before_action :authorize_restaurant_owner
  
  # GET /restaurants/:restaurant_id/ocr_menu_imports
  def index
    @ocr_menu_imports = @restaurant.ocr_menu_imports.recent
  end
  
  # GET /restaurants/:restaurant_id/ocr_menu_imports/new
  def new
    @ocr_menu_import = @restaurant.ocr_menu_imports.new
  end
  
  # POST /restaurants/:restaurant_id/ocr_menu_imports
  def create
    @ocr_menu_import = @restaurant.ocr_menu_imports.new(ocr_menu_import_params)
    
    if @ocr_menu_import.save
      if @ocr_menu_import.pdf_file.attached?
        @ocr_menu_import.process_pdf_async
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import), 
                    notice: 'Menu import has been queued for processing.'
      else
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import), 
                    alert: 'Please attach a PDF file.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id/edit
  def edit
    @ocr_menu_sections = @ocr_menu_import.ocr_menu_sections.ordered.includes(:ocr_menu_items)
  end
  
  # PATCH/PUT /restaurants/:restaurant_id/ocr_menu_imports/:id
  def update
    if @ocr_menu_import.update(ocr_menu_import_params)
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                  notice: 'Menu import was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  # GET /restaurants/:restaurant_id/ocr_menu_imports/:id
  def show
    @ocr_menu_sections = @ocr_menu_import.ocr_menu_sections.ordered.includes(:ocr_menu_items)
    
    respond_to do |format|
      format.html
      format.json { render json: @ocr_menu_import }
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
                  notice: 'Processing has been (re)started.'
    else
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import),
                  alert: "Unable to (re)start processing from status: #{@ocr_menu_import.status}."
    end
  end
  
  # POST /restaurants/:restaurant_id/ocr_menu_imports/:id/confirm_import
  def confirm_import
    if @ocr_menu_import.completed? && @ocr_menu_import.ocr_menu_sections.confirmed.any?
      menu = create_menu_from_import
      if menu.persisted?
        @ocr_menu_import.update(menu: menu)
        redirect_to restaurant_menu_path(@restaurant, menu), 
                    notice: 'Menu has been successfully imported!'
      else
        redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import), 
                    alert: 'Failed to create menu: ' + menu.errors.full_messages.join(', ')
      end
    else
      redirect_to restaurant_ocr_menu_import_path(@restaurant, @ocr_menu_import), 
                  alert: 'Please confirm at least one section before importing.'
    end
  end
  
  # PATCH /restaurants/:restaurant_id/ocr_menu_imports/:id/reorder_sections
  def reorder_sections
    section_ids = Array(params[:section_ids]).reject(&:blank?).map(&:to_i)
    Rails.logger.warn("[reorder_sections] raw=#{params[:section_ids].inspect} parsed=#{section_ids.inspect}")
    return render(json: { error: 'section_ids required' }, status: :bad_request) if section_ids.blank?

    # Ensure all sections belong to this import for safety and in given order
    sections = @ocr_menu_import.ocr_menu_sections.where(id: section_ids)
    Rails.logger.warn("[reorder_sections] found #{sections.size} matching sections for ids #{section_ids.inspect} (expected #{section_ids.size})")
    return render(json: { error: 'sections mismatch' }, status: :unprocessable_entity) if sections.size != section_ids.size

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
    section_id = params[:section_id].to_i
    item_ids = Array(params[:item_ids]).reject(&:blank?).map(&:to_i)
    Rails.logger.warn("[reorder_items] section_id raw=#{params[:section_id].inspect} parsed=#{section_id} item_ids raw=#{params[:item_ids].inspect} parsed=#{item_ids.inspect}")
    return render(json: { error: 'section_id and item_ids required' }, status: :bad_request) if section_id.zero? || item_ids.blank?

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
    redirect_to restaurant_ocr_menu_imports_path(@restaurant), 
                notice: 'Menu import was successfully deleted.'
  end
  
  private
  
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end
  
  def set_ocr_menu_import
    @ocr_menu_import = @restaurant.ocr_menu_imports.find(params[:id])
  end
  
  def ocr_menu_import_params
    params.require(:ocr_menu_import).permit(:name, :pdf_file)
  end
  
  def authorize_restaurant_owner
    unless current_user && @restaurant.user == current_user
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
    end
  end
  
  def create_menu_from_import
    Menu.transaction do
      menu = @restaurant.menus.create!(
        name: @ocr_menu_import.name,
        description: "Imported from PDF on #{Time.current.strftime('%B %d, %Y')}",
        active: true
      )
      
      @ocr_menu_import.ocr_menu_sections.confirmed.ordered.each do |section|
        menu_section = menu.menusections.create!(
          name: section.name,
          sequence: section.sequence,
          active: true
        )
        
        section.ocr_menu_items.ordered.each do |item|
          menu_section.menuitems.create!(
            name: item.name,
            description: item.description,
            price: item.price,
            sequence: item.sequence,
            active: true,
            vegetarian: item.is_vegetarian,
            vegan: item.is_vegan,
            gluten_free: item.is_gluten_free,
            allergens: item.allergens.join(', ')
          )
        end
      end
      
      menu
    end
  rescue StandardError => e
    Rails.logger.error "Error creating menu from import: #{e.message}"
    Menu.new # Return an unsaved menu to handle errors
  end
end

