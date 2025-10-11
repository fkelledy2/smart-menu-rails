class OcrMenuItemResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :description, index: false
  attribute :price
  attribute :sequence
  attribute :is_confirmed
  attribute :allergens, index: false
  attribute :is_vegetarian
  attribute :is_vegan
  attribute :is_gluten_free
  attribute :is_dairy_free
  attribute :metadata, index: false
  attribute :page_reference, index: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :ocr_menu_section
  attribute :menu_item
  attribute :menuitem

  # Customize the display name of records in the admin area
  def self.display_name(record)
    price_display = record.price ? "$#{record.price}" : 'No price'
    "#{record.name} - #{price_display}"
  end

  # Customize the default sort column and direction
  def self.default_sort_column
    'sequence'
  end

  def self.default_sort_direction
    'asc'
  end
end
