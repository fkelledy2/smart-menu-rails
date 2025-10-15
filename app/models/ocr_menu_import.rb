class OcrMenuImport < ApplicationRecord
  include AASM
  include IdentityCache

  # Associations
  belongs_to :restaurant
  belongs_to :menu, optional: true
  has_many :ocr_menu_sections, dependent: :destroy
  has_many :ocr_menu_items, through: :ocr_menu_sections
  has_one_attached :pdf_file

  # IdentityCache configuration (minimal to support Restaurant.cache_has_many :ocr_menu_imports)
  cache_index :id
  cache_belongs_to :restaurant

  # Validations
  validates :name, presence: true
  validates :status, presence: true

  # State machine for tracking import progress
  aasm column: 'status' do
    state :pending, initial: true
    state :processing, :completed, :failed

    event :process do
      transitions from: %i[pending failed], to: :processing, after: proc {
        # Reset error/progress fields when (re)starting processing
        update_columns(
          error_message: nil,
          failed_at: nil,
          processed_pages: 0,
          total_pages: nil,
          updated_at: Time.current,
        )
      }
    end

    event :complete do
      transitions from: :processing, to: :completed
      after do
        update(completed_at: Time.current)
      end
    end

    event :fail do
      transitions from: %i[pending processing], to: :failed
      after do |error_message|
        update(failed_at: Time.current, error_message: error_message)
      end
    end
  end

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  # Instance methods
  # Alias for progress_percentage to match test expectations
  def progress
    progress_percentage
  end

  def progress_percentage
    return 0 if total_pages.blank? || total_pages.zero?

    (processed_pages.to_f / total_pages * 100).round(2)
  end

  def process_pdf_async
    PdfMenuExtractionJob.perform_later(id)
  end

  # Process menu data from OCR results
  def process_menu_data(menu_data)
    transaction do
      # Process sections
      menu_data[:sections]&.each_with_index do |section_data, section_index|
        section = ocr_menu_sections.create!(
          name: section_data[:name],
          sequence: section_index,
          metadata: { description: section_data[:description] },
        )

        # Process items in each section
        section_data[:items]&.each_with_index do |item_data, item_index|
          section.ocr_menu_items.create!(
            name: item_data[:name],
            description: item_data[:description],
            price: item_data[:price],
            allergens: item_data[:allergens] || [],
            sequence: item_index,
            is_confirmed: false,
            is_vegetarian: item_data[:is_vegetarian] || false,
            is_vegan: item_data[:is_vegan] || false,
            is_gluten_free: item_data[:is_gluten_free] || false,
            metadata: {},
          )
        end
      end

      # Update import status
      update(total_pages: 1, processed_pages: 1) # Assuming 1 page for now
    end
  end

  # Update progress of the import
  def update_progress(processed, total)
    update(processed_pages: processed, total_pages: total)
  end

  # Returns the current page being processed
  def current_page
    processed_pages
  end

  # Attach a PDF file to the import
  def attach_pdf(file)
    pdf_file.attach(file)
  end

  # Reorder sections given an ordered array of section IDs
  # Returns true if successful, otherwise raises
  def reorder_sections!(ordered_section_ids)
    ids = Array(ordered_section_ids).compact_blank.map(&:to_i)
    raise ArgumentError, 'section_ids required' if ids.blank?

    sections = ocr_menu_sections.where(id: ids)
    raise ActiveRecord::RecordInvalid, self if sections.size != ids.size

    OcrMenuSection.transaction do
      ids.each_with_index do |sid, idx|
        section = ocr_menu_sections.find_by(id: sid)
        raise ActiveRecord::RecordNotFound, 'section not found' unless section

        section.update!(sequence: idx + 1)
      end
    end
    true
  end

  # Reorder items within a specific section
  # section_id: Integer, ordered_item_ids: [Integer]
  def reorder_items!(section_id, ordered_item_ids)
    sid = section_id.to_i
    ids = Array(ordered_item_ids).compact_blank.map(&:to_i)
    raise ArgumentError, 'section_id and item_ids required' if sid.zero? || ids.blank?

    section = ocr_menu_sections.find_by(id: sid)
    raise ActiveRecord::RecordNotFound, 'section not found' unless section

    items = section.ocr_menu_items.where(id: ids)
    raise ActiveRecord::RecordInvalid, section if items.size != ids.size

    OcrMenuItem.transaction do
      ids.each_with_index do |iid, idx|
        item = section.ocr_menu_items.find_by(id: iid)
        raise ActiveRecord::RecordNotFound, 'item not found' unless item

        item.update!(sequence: idx + 1)
      end
    end
    true
  end
end
