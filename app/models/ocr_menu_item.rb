class OcrMenuItem < ApplicationRecord
  # Associations
  belongs_to :ocr_menu_section
  belongs_to :menu_item, optional: true
  belongs_to :menuitem, class_name: 'Menuitem', foreign_key: :menuitem_id, optional: true
  
  # Backward compatibility: some tests refer to `position`
  alias_attribute :position, :sequence

  # Validations
  validates :name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :ordered, -> { order(sequence: :asc) }
  scope :confirmed, -> { where(is_confirmed: true) }
  scope :pending_confirmation, -> { where(is_confirmed: false) }
  scope :vegetarian, -> { where(is_vegetarian: true) }
  scope :vegan, -> { where(is_vegan: true) }
  scope :gluten_free, -> { where(is_gluten_free: true) }
  
  # Callbacks
  before_validation :set_default_sequence, on: :create
  before_save :normalize_allergens
  
  # Instance methods
  def confirm!
    update!(is_confirmed: true)
  end
  
  def unconfirm!
    update!(is_confirmed: false)
  end
  
  def to_s
    "#{sequence}. #{name} - #{formatted_price}"
  end
  
  def formatted_price
    return 'Price not set' if price.blank?
    "$#{'%.2f' % price.to_f}"
  end
  
  def has_allergens?
    allergens.present? && allergens.any?(&:present?)
  end
  
  def dietary_restrictions
    restrictions = []
    restrictions << 'Vegetarian' if is_vegetarian?
    restrictions << 'Vegan' if is_vegan?
    restrictions << 'Gluten Free' if is_gluten_free?
    restrictions.join(', ')
  end
  
  private
  
  def set_default_sequence
    return if sequence.present?
    self.sequence = (ocr_menu_section.ocr_menu_items.maximum(:sequence) || 0) + 1
  end
  
  def normalize_allergens
    return if allergens.blank?
    self.allergens = allergens.reject(&:blank?).map(&:strip).map(&:downcase).uniq
  end
end
