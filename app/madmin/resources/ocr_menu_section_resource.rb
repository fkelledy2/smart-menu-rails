class OcrMenuSectionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :description
  attribute :sequence
  attribute :is_confirmed
  attribute :metadata, index: false
  attribute :page_reference, index: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :ocr_menu_import
  attribute :menu_section
  attribute :menusection
  attribute :ocr_menu_items

  # Customize the display name of records in the admin area
  def self.display_name(record)
    "#{record.name} (#{record.ocr_menu_import&.name})"
  end

  # Customize the default sort column and direction
  def self.default_sort_column
    'sequence'
  end

  def self.default_sort_direction
    'asc'
  end
end
