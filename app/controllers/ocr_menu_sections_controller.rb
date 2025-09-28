class OcrMenuSectionsController < ApplicationController
  # Allow JSON API-style updates without CSRF token
  skip_before_action :verify_authenticity_token, only: :update
  before_action :set_section

  # PATCH /ocr_menu_sections/:id
  def update
    request.format = :json if request.format.html?
    attrs = section_params

    if attrs.blank? && !params.dig(:ocr_menu_section, :name) && !params.dig(:ocr_menu_section, :description)
      return render json: { ok: false, errors: ["Empty payload"] }, status: :unprocessable_entity
    end

    if attrs.key?(:name) && attrs[:name].to_s.strip.empty?
      return render json: { ok: false, errors: ["Name can't be blank"] }, status: :unprocessable_entity
    end

    if @section.update(attrs)
      render json: { ok: true, section: { id: @section.id, name: @section.name } }
    else
      render json: { ok: false, errors: @section.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing
    render json: { ok: false, errors: ["Invalid parameters"] }, status: :unprocessable_entity
  end

  private

  def set_section
    @section = OcrMenuSection.find(params[:id])
  end

  def section_params
    params.fetch(:ocr_menu_section, {}).permit(:name, :description)
  end
end
