class OcrMenuSection < ApplicationRecord
  # Associations
  belongs_to :ocr_menu_import
  belongs_to :menu_section, optional: true
  has_many :ocr_menu_items, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :ordered, -> { order(sequence: :asc) }
  scope :confirmed, -> { where(is_confirmed: true) }
  scope :pending_confirmation, -> { where(is_confirmed: false) }
  
  # Instance methods
  def confirm!
    update!(is_confirmed: true)
  end
  
  def unconfirm!
    update!(is_confirmed: false)
  end
  
  def to_s
    "#{sequence}. #{name}"
  end
end
