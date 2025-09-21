require 'set'
class OcrMenuItemsController < ApplicationController
  protect_from_forgery with: :exception
  before_action :set_item

  # PATCH /ocr_menu_items/:id
  def update
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
      rescue
        0
      end
    end

    # map dietary_restrictions array to boolean flags
    restrictions = (params.dig(:ocr_menu_item, :dietary_restrictions) || [])
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
        begin
          allergens = JSON.parse(allergens) rescue []
        end
      end
      if allergens.is_a?(Array)
        attrs[:allergens] = allergens.compact.map { |a| a.to_s.strip.downcase }.reject(&:blank?).uniq
      end
    end

    if @item.update(attrs)
      render json: { ok: true, item: serialize_item(@item) }
    else
      render json: { ok: false, errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = OcrMenuItem.find(params[:id])
  end

  def permitted_item_params
    # Only allow the fields we expect to edit here
    params.require(:ocr_menu_item).permit(:name, :description, :price)
  end

  def normalize_restrictions(arr)
    set = arr.map { |v| v.to_s.downcase.strip }.to_set
    {
      is_vegetarian: set.include?("vegetarian"),
      is_vegan: set.include?("vegan"),
      is_gluten_free: set.include?("gluten_free"),
      is_dairy_free: set.include?("dairy_free"),
      is_nut_free: set.include?("nut_free")
    }
  end

  def serialize_item(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      allergens: item.allergens,
      is_vegetarian: item.respond_to?(:is_vegetarian) ? item.is_vegetarian : false,
      is_vegan: item.respond_to?(:is_vegan) ? item.is_vegan : false,
      is_gluten_free: item.respond_to?(:is_gluten_free) ? item.is_gluten_free : false,
      is_dairy_free: item.respond_to?(:is_dairy_free) ? item.is_dairy_free : false,
      is_nut_free: item.respond_to?(:is_nut_free) ? item.is_nut_free : false
    }
  end
end
