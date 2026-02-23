class OcrMenuItemsController < ApplicationController
  include Pundit::Authorization

  protect_from_forgery with: :exception
  # Allow JSON API-style updates in tests and clients without CSRF token
  skip_before_action :verify_authenticity_token, only: :update
  before_action :authenticate_user!
  before_action :set_item
  before_action :authorize_item

  # PATCH /ocr_menu_items/:id
  def update
    if Rails.env.test?
      Rails.logger.warn '[TEST DEBUG] HIT OcrMenuItemsController#update (NON-API)'
    end
    request.format = :json if request.format.html?
    # Accept JSON payload like:
    # {
    #   ocr_menu_item: {
    #     name: "...",
    #     description: "...",
    #     price: 12.34,
    #     allergens: ["gluten", "dairy"],
    #     dietary_restrictions: ["vegetarian", "vegan", "gluten_free", "dairy_free", "nut_free"]
    #   }
    # }
    attrs = permitted_item_params

    # normalize price
    if attrs.key?(:price)
      attrs[:price] = begin
        BigDecimal(attrs[:price].to_s)
      rescue StandardError
        0
      end
    end

    # map dietary_restrictions array to boolean flags
    restrictions = params.dig(:ocr_menu_item, :dietary_restrictions) || []
    if restrictions.is_a?(Array)
      flags = normalize_restrictions(restrictions)
      # Only include flags for attributes that actually exist on the model
      safe_flags = flags.each_with_object({}) do |(k, v), h|
        h[k] = v if @item.has_attribute?(k.to_s)
      end
      attrs.merge!(safe_flags)
    end

    # normalize allergens (array of strings)
    if params.dig(:ocr_menu_item, :allergens)
      allergens = params[:ocr_menu_item][:allergens]
      if allergens.is_a?(String)

        allergens = begin
          JSON.parse(allergens)
        rescue StandardError
          []
        end

      end
      if allergens.is_a?(Array)
        attrs[:allergens] = allergens.compact.map { |a| a.to_s.strip.downcase }.compact_blank.uniq
      end
    end

    if attrs.blank? && !params.dig(:ocr_menu_item, :allergens) && !params.dig(:ocr_menu_item, :dietary_restrictions)
      return render json: { ok: false, errors: ['Empty payload'] }, status: :unprocessable_content
    end

    # basic guardrails to satisfy API contract and tests
    guard_errors = []
    guard_errors << "Name can't be blank" if attrs.key?(:name) && attrs[:name].to_s.strip.empty?
    guard_errors << 'Price must be greater than or equal to 0' if attrs.key?(:price) && attrs[:price].to_f.negative?
    if guard_errors.any?
      return render json: { ok: false, errors: guard_errors }, status: :unprocessable_content
    end

    # Merge metadata overrides (alcohol flags) if provided
    if params.dig(:ocr_menu_item, :metadata).present?
      md = begin
        params[:ocr_menu_item][:metadata].to_unsafe_h.symbolize_keys
      rescue StandardError
        {}
      end
      safe_md = {}
      if md.key?(:alcohol_override)
        # expected values: 'alcoholic', 'non_alcoholic', 'undecided'
        safe_md[:alcohol_override] = md[:alcohol_override].to_s
      end
      safe_md[:alcohol_abv] = md[:alcohol_abv] if md.key?(:alcohol_abv)
      safe_md[:alcohol_classification] = md[:alcohol_classification].to_s if md.key?(:alcohol_classification)
      @item.metadata ||= {}
      @item.metadata.merge!(safe_md)
    end

    # Handle size_prices (stored in metadata)
    if params.dig(:ocr_menu_item, :size_prices).present?
      sp = params[:ocr_menu_item][:size_prices]
      sp = sp.to_unsafe_h if sp.respond_to?(:to_unsafe_h)
      cleaned = sp.each_with_object({}) do |(k, v), h|
        key = k.to_s
        next unless %w[glass large_glass half_bottle bottle carafe].include?(key)
        val = v.to_f
        h[key] = val if val > 0
      end
      @item.metadata ||= {}
      @item.metadata['size_prices'] = cleaned
    end

    # Allow flat params too (from simple inline editors)
    if params.key?(:alcohol_override) || params.key?(:alcohol_abv) || params.key?(:alcohol_classification)
      @item.metadata ||= {}
      @item.metadata[:alcohol_override] = params[:alcohol_override].to_s if params.key?(:alcohol_override)
      @item.metadata[:alcohol_abv] = params[:alcohol_abv] if params.key?(:alcohol_abv)
      @item.metadata[:alcohol_classification] = params[:alcohol_classification].to_s if params.key?(:alcohol_classification)
    end

    if @item.update(attrs)
      render json: { ok: true, item: serialize_item(@item) }
    else
      render json: { ok: false, errors: @item.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActionController::ParameterMissing
    render json: { ok: false, errors: ['Invalid parameters'] }, status: :unprocessable_content
  end

  private

  def set_item
    @item = OcrMenuItem.find(params[:id])
  end

  def authorize_item
    if Rails.env.test?
      Rails.logger.warn '[TEST DEBUG] OcrMenuItemsController#authorize_item: about to call authorize'
    end
    authorize @item
    if Rails.env.test?
      Rails.logger.warn '[TEST DEBUG] OcrMenuItemsController#authorize_item: authorize passed'
    end
  rescue Pundit::NotAuthorizedError
    if Rails.env.test?
      Rails.logger.warn '[TEST DEBUG] OcrMenuItemsController#authorize_item: Pundit::NotAuthorizedError caught'
    end
    render json: { ok: false, errors: ['You are not authorized to perform this action'] }, status: :forbidden
  end

  def permitted_item_params
    # Only allow the fields we expect to edit here; tolerate missing root key
    params.fetch(:ocr_menu_item, {}).permit(:name, :description, :price, :image_prompt)
  end

  def normalize_restrictions(arr)
    set = arr.to_set { |v| v.to_s.downcase.strip }
    {
      is_vegetarian: set.include?('vegetarian'),
      is_vegan: set.include?('vegan'),
      is_gluten_free: set.include?('gluten_free'),
      is_dairy_free: set.include?('dairy_free'),
      is_nut_free: set.include?('nut_free'),
    }
  end

  def serialize_item(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      image_prompt: item.respond_to?(:image_prompt) ? item.image_prompt : nil,
      price: item.price,
      allergens: item.allergens,
      is_vegetarian: item.respond_to?(:is_vegetarian) ? item.is_vegetarian : false,
      is_vegan: item.respond_to?(:is_vegan) ? item.is_vegan : false,
      is_gluten_free: item.respond_to?(:is_gluten_free) ? item.is_gluten_free : false,
      is_dairy_free: item.respond_to?(:is_dairy_free) ? item.is_dairy_free : false,
      is_nut_free: item.respond_to?(:is_nut_free) ? item.is_nut_free : false,
      size_prices: (item.metadata || {})['size_prices'] || {},
    }
  end
end
