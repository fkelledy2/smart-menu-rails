class OcrMenuImportResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :status
  attribute :error_message, index: false
  attribute :total_pages
  attribute :processed_pages
  attribute :metadata, index: false
  attribute :completed_at, form: false
  attribute :failed_at, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :restaurant
  attribute :menu
  attribute :ocr_menu_sections
  attribute :ocr_menu_items
  attribute :pdf_file, index: false

  # Customize the display name of records in the admin area
  def self.display_name(record)
    "#{record.name} (#{record.status})"
  end

  # Customize the default sort column and direction
  def self.default_sort_column
    "created_at"
  end

  def self.default_sort_direction
    "desc"
  end
end
