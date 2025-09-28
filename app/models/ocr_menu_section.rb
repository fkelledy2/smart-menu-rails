class OcrMenuSection < ApplicationRecord
  # Associations
  belongs_to :ocr_menu_import
  belongs_to :menu_section, optional: true
  belongs_to :menusection, class_name: 'Menusection', foreign_key: :menusection_id, optional: true
  has_many :ocr_menu_items, dependent: :destroy
  
  # Backward compatibility: some tests refer to `position`
  alias_attribute :position, :sequence
  
  # Validations
  validates :name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # Callbacks
  before_validation :set_default_sequence, on: :create

  # Scopes
  scope :ordered, -> { order(sequence: :asc) }
  scope :confirmed, -> { where(is_confirmed: true) }
  scope :pending_confirmation, -> { where(is_confirmed: false) }
  
  # Instance methods
  def confirm!
    transaction do
      update!(is_confirmed: true)
      # Tests expect items in the section to be confirmed when the section is confirmed
      ocr_menu_items.update_all(is_confirmed: true)
    end
  end
  
  def unconfirm!
    update!(is_confirmed: false)
  end
  
  # Backward-compatible predicate expected by some tests
  def confirmed?
    is_confirmed?
  end
  
  def to_s
    "#{sequence}. #{name}"
  end

  # Tests call this to populate items from a section-shaped hash
  def create_items_from_data(section_data)
    self.name = section_data[:name] if section_data[:name].present?
    # store description in metadata to preserve API without schema changes
    self.metadata ||= {}
    self.metadata[:description] = section_data[:description] if section_data[:description].present?
    save! if new_record? || changed?

    Array(section_data[:items]).each_with_index do |item_data, idx|
      OcrMenuItem.create_from_data(self, item_data.symbolize_keys, idx + 1)
    end
  end

  private

  def set_default_sequence
    return if sequence.present?
    self.sequence = (ocr_menu_import&.ocr_menu_sections&.maximum(:sequence) || 0) + 1
  end
end
