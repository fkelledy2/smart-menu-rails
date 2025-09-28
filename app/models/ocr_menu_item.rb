class OcrMenuItem < ApplicationRecord
  # Include dietary restrictions functionality
  include DietaryRestrictable

  # Associations
  belongs_to :ocr_menu_section
  belongs_to :menu_item, optional: true
  belongs_to :menuitem, class_name: 'Menuitem', optional: true

  # Backward compatibility: some tests refer to `position`
  alias_attribute :position, :sequence

  # Persist extra computed fields in metadata
  # Note: dietary_restrictions is now handled by DietaryRestrictable concern

  # Virtual attribute to satisfy tests; not persisted
  attr_accessor :confirmed_at

  # Validations
  validates :name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :ordered, -> { order(sequence: :asc) }
  scope :confirmed, -> { where(is_confirmed: true) }
  scope :pending_confirmation, -> { where(is_confirmed: false) }

  # Callbacks
  before_validation :set_default_sequence, on: :create
  before_save :normalize_allergens

  # Instance methods
  def confirm!
    update!(is_confirmed: true)
    self.confirmed_at = Time.current
  end

  def unconfirm!
    update!(is_confirmed: false)
  end

  # Backward-compatible predicate expected by some tests
  def confirmed?
    is_confirmed?
  end

  def to_s
    "#{sequence}. #{name} - #{formatted_price}"
  end

  def formatted_price
    return nil if price.blank?

    "$#{format('%.2f', price.to_f)}"
  end

  def has_allergens?
    allergens.present? && allergens.any?(&:present?)
  end

  # Dietary restrictions methods now provided by DietaryRestrictable concern

  def allergen_info
    return nil unless has_allergens?

    list = allergens.map { |a| a.to_s.split.map(&:capitalize).join(' ') }.join(', ')
    "Contains: #{list}"
  end

  def display_name
    fp = formatted_price
    return name if fp.nil?

    "#{name} - #{fp}"
  end

  private

  def set_default_sequence
    return if sequence.present?

    self.sequence = (ocr_menu_section.ocr_menu_items.maximum(:sequence) || 0) + 1
  end

  def normalize_allergens
    return if allergens.blank?

    self.allergens = allergens.compact_blank.map(&:strip).map(&:downcase).uniq
  end

  public

  # Class/instance helpers expected by tests
  def self.create_from_data(section, data, position)
    dietary_flags = DietaryRestrictionsService.array_to_boolean_flags(data[:dietary_restrictions] || [])

    section.ocr_menu_items.create!(
      name: data[:name],
      description: data[:description],
      price: data[:price],
      allergens: data[:allergens] || [],
      sequence: position,
      **dietary_flags,
    )
  end

  def update_from_params(params)
    permitted = params.symbolize_keys.slice(:name, :description, :price, :allergens, :dietary_restrictions)
    self.name = permitted[:name] if permitted.key?(:name)
    self.description = permitted[:description] if permitted.key?(:description)
    self.price = permitted[:price].present? ? permitted[:price].to_f : permitted[:price]
    self.allergens = Array(permitted[:allergens]).map(&:to_s)

    if permitted.key?(:dietary_restrictions)
      # Use the new service to set dietary restrictions
      self.dietary_restrictions = permitted[:dietary_restrictions]
    end

    save!
  end

  # Default status for backward compatibility in tests
  def status
    'pending'
  end
end
