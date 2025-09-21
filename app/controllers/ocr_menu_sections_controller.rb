class OcrMenuSectionsController < ApplicationController
  before_action :set_section

  # PATCH /ocr_menu_sections/:id
  def update
    if @section.update(section_params)
      render json: { ok: true, section: { id: @section.id, name: @section.name } }
    else
      render json: { ok: false, errors: @section.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_section
    @section = OcrMenuSection.find(params[:id])
  end

  def section_params
    params.require(:ocr_menu_section).permit(:name, :description)
  end
end
