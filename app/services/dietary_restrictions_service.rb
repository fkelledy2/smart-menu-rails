# Centralized service for handling dietary restrictions across the application
# Consolidates the various formats and provides a single canonical source
class DietaryRestrictionsService
  # Canonical list of supported dietary restrictions
  SUPPORTED_RESTRICTIONS = %w[
    vegetarian
    vegan
    gluten_free
    dairy_free
  ].freeze

  # Mapping from restriction names to boolean attribute names
  RESTRICTION_TO_BOOLEAN = {
    'vegetarian' => :is_vegetarian,
    'vegan' => :is_vegan,
    'gluten_free' => :is_gluten_free,
    'dairy_free' => :is_dairy_free,
  }.freeze

  # Mapping from boolean attributes to restriction names
  BOOLEAN_TO_RESTRICTION = RESTRICTION_TO_BOOLEAN.invert.transform_keys(&:to_s).freeze

  class << self
    # Normalize an array of dietary restrictions to canonical format
    # @param restrictions [Array, String, nil] Raw dietary restrictions input
    # @return [Array<String>] Normalized array of canonical restriction names
    def normalize_array(restrictions)
      Array(restrictions)
        .compact
        .map { |r| r.to_s.strip.downcase }
        .select { |r| SUPPORTED_RESTRICTIONS.include?(r) }
        .uniq
    end

    # Convert dietary restrictions array to boolean flags hash
    # @param restrictions [Array<String>] Array of restriction names
    # @return [Hash] Hash of boolean flags (e.g., { is_vegetarian: true, is_vegan: false })
    def array_to_boolean_flags(restrictions)
      normalized = normalize_array(restrictions)

      RESTRICTION_TO_BOOLEAN.each_with_object({}) do |(restriction_name, boolean_attr), result|
        result[boolean_attr] = normalized.include?(restriction_name)
      end
    end

    # Extract dietary restrictions array from boolean flags
    # @param record [ActiveRecord::Base] Record with boolean dietary restriction attributes
    # @return [Array<String>] Array of restriction names
    def boolean_flags_to_array(record)
      return [] unless record # Handle nil record

      restrictions = []

      RESTRICTION_TO_BOOLEAN.each do |restriction_name, boolean_attr|
        if record.respond_to?(boolean_attr) && record.public_send(boolean_attr)
          restrictions << restriction_name
        end
      end

      restrictions
    end

    # Get human-readable display text for dietary restrictions
    # @param restrictions [Array<String>] Array of restriction names
    # @return [String, nil] Formatted display text or nil if no restrictions
    def display_text(restrictions)
      normalized = normalize_array(restrictions)
      return nil if normalized.empty?

      normalized.map { |r| r.tr('_', ' ').split.map(&:capitalize).join(' ') }.join(', ')
    end

    # Check if a record has any dietary restrictions
    # @param record [ActiveRecord::Base] Record to check
    # @return [Boolean] True if record has any dietary restrictions
    def has_restrictions?(record)
      boolean_flags_to_array(record).any?
    end

    # Update a record's dietary restriction boolean flags from an array
    # @param record [ActiveRecord::Base] Record to update
    # @param restrictions [Array<String>] Array of restriction names
    # @return [Hash] Hash of attributes to assign
    def update_boolean_flags(record, restrictions)
      flags = array_to_boolean_flags(restrictions)

      # Only return flags that the record actually supports
      flags.select { |attr, _value| record.respond_to?("#{attr}=") }
    end

    # Validate dietary restrictions array
    # @param restrictions [Array] Array to validate
    # @return [Array<String>] Array of validation errors
    def validate_restrictions(restrictions)
      errors = []

      return errors if restrictions.blank?

      Array(restrictions).each do |restriction|
        normalized = restriction.to_s.strip.downcase
        unless SUPPORTED_RESTRICTIONS.include?(normalized)
          errors << "Unsupported dietary restriction: #{restriction}"
        end
      end

      errors
    end

    # Get all supported dietary restrictions with display names
    # @return [Hash] Hash mapping restriction names to display names
    def supported_restrictions_with_display_names
      SUPPORTED_RESTRICTIONS.each_with_object({}) do |restriction, hash|
        display_name = restriction.tr('_', ' ').split.map(&:capitalize).join(' ')
        hash[restriction] = display_name
      end
    end
  end
end
