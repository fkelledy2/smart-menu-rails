# Concern for models that support dietary restrictions
# Provides consistent behavior across different models (OcrMenuItem, Menuitem, etc.)
module DietaryRestrictable
  extend ActiveSupport::Concern

  included do
    # Scopes for dietary restrictions
    scope :vegetarian, -> { where(is_vegetarian: true) }
    scope :vegan, -> { where(is_vegan: true) }
    scope :gluten_free, -> { where(is_gluten_free: true) }
    scope :dairy_free, -> { where(is_dairy_free: true) }

    # Scope to find items with any dietary restrictions
    scope :with_dietary_restrictions, lambda {
      where(
        DietaryRestrictionsService::RESTRICTION_TO_BOOLEAN.values
          .map { |attr| "#{attr} = ?" }
          .join(' OR '),
        *([true] * DietaryRestrictionsService::RESTRICTION_TO_BOOLEAN.size),
      )
    }
  end

  # Get dietary restrictions as an array
  # @return [Array<String>] Array of dietary restriction names
  def dietary_restrictions
    # Check if stored in metadata first (for backward compatibility)
    if respond_to?(:metadata) && metadata.present? && metadata.is_a?(Hash) && metadata.key?('dietary_restrictions')
      stored_value = metadata['dietary_restrictions']
      return DietaryRestrictionsService.normalize_array(stored_value)
    end

    # Otherwise, extract from boolean flags
    result = DietaryRestrictionsService.boolean_flags_to_array(self)
    result || [] # Ensure we always return an array
  end

  # Set dietary restrictions from an array
  # @param restrictions [Array<String>] Array of dietary restriction names
  def dietary_restrictions=(restrictions)
    # Update boolean flags
    flags = DietaryRestrictionsService.update_boolean_flags(self, restrictions)
    flags.each { |attr, value| public_send("#{attr}=", value) }

    # Also store in metadata if the model supports it (for backward compatibility)
    return unless respond_to?(:metadata=)

    self.metadata = (metadata || {}).merge(
      'dietary_restrictions' => DietaryRestrictionsService.normalize_array(restrictions),
    )
  end

  # Get human-readable dietary restrictions text
  # @return [String, nil] Formatted display text or nil if no restrictions
  def dietary_info
    DietaryRestrictionsService.display_text(dietary_restrictions)
  end

  # Check if this item has any dietary restrictions
  # @return [Boolean] True if item has any dietary restrictions
  def has_dietary_restrictions?
    DietaryRestrictionsService.has_restrictions?(self)
  end

  # Check if this item matches specific dietary restrictions
  # @param required_restrictions [Array<String>] Required dietary restrictions
  # @return [Boolean] True if item satisfies all required restrictions
  def matches_dietary_restrictions?(required_restrictions)
    return true if required_restrictions.blank?

    item_restrictions = dietary_restrictions
    DietaryRestrictionsService.normalize_array(required_restrictions).all? do |required|
      item_restrictions.include?(required)
    end
  end

  # Validate dietary restrictions
  # @return [Array<String>] Array of validation errors
  def validate_dietary_restrictions
    DietaryRestrictionsService.validate_restrictions(dietary_restrictions)
  end

  class_methods do
    # Find items matching specific dietary restrictions
    # @param restrictions [Array<String>] Required dietary restrictions
    # @return [ActiveRecord::Relation] Filtered relation
    def matching_dietary_restrictions(restrictions)
      return all if restrictions.blank?

      normalized = DietaryRestrictionsService.normalize_array(restrictions)
      conditions = normalized.filter_map do |restriction|
        boolean_attr = DietaryRestrictionsService::RESTRICTION_TO_BOOLEAN[restriction]
        "#{boolean_attr} = ?" if boolean_attr
      end

      return none if conditions.empty?

      where(conditions.join(' AND '), *([true] * conditions.size))
    end
  end
end
