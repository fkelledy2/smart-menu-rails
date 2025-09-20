class OcrMenuImportsController < ApplicationController
  before_action :set_restaurant
  before_action :set_ocr_menu_import, only: [:show, :edit, :update, :destroy, :process_pdf, :confirm_import]
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
    section_ids = Array(params[:section_ids]).map(&:to_i)
    return head :bad_request if section_ids.blank?

    # Ensure all sections belong to this import for safety
    sections = @ocr_menu_import.ocr_menu_sections.where(id: section_ids)
    return head :unprocessable_entity if sections.size != section_ids.size

    OcrMenuSection.transaction do
      section_ids.each_with_index do |sid, idx|
        OcrMenuSection.where(id: sid, ocr_menu_import_id: @ocr_menu_import.id)
                       .update_all(sequence: idx + 1, updated_at: Time.current)
      end
    end

    head :ok
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

