require 'test_helper'

class PdfMenuProcessorTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Processor Import')
  end

  test 'process returns false when no pdf attached' do
    processor = PdfMenuProcessor.new(@import)
    assert_nil processor.process
  end

  test 'process persists empty structure when chatgpt returns empty' do
    fake_openai = Minitest::Mock.new
    def fake_openai.chat(*) = { 'choices' => [{ 'message' => { 'content' => { sections: [] }.to_json } }] }

    attach_blank_pdf(@import)
    processor = PdfMenuProcessor.new(@import, openai_client: fake_openai)
    processor.stub :extract_text_from_pdf, '' do
      assert processor.process
    end

    @import.reload
    assert_equal 0, @import.ocr_menu_sections.count
  end

  test 'process persists sections and items on successful parse' do
    attach_blank_pdf(@import)
    processor = PdfMenuProcessor.new(@import)
    sample = {
      sections: [
        {
          name: 'Starters',
          description: '',
          items: [
            { name: 'Soup', description: 'Tomato', price: 5.5, allergens: ['gluten'] },
          ],
        },
      ],
    }

    processor.stub :extract_text_from_pdf, 'menu text' do
      processor.stub :parse_menu_with_chatgpt, sample do
        assert processor.process
      end
    end

    @import.reload
    assert_equal 1, @import.ocr_menu_sections.count
    section = @import.ocr_menu_sections.first
    assert_equal 'Starters', section.name
    assert_equal 1, section.ocr_menu_items.count
    assert_equal 'Soup', section.ocr_menu_items.first.name
  end

  test 'process raises ProcessingError when extraction fails' do
    attach_blank_pdf(@import)
    processor = PdfMenuProcessor.new(@import)
    processor.stub :extract_text_from_pdf, -> { raise StandardError, 'boom' } do
      assert_raises PdfMenuProcessor::ProcessingError do
        processor.process
      end
    end
  end

  private

  def attach_blank_pdf(import)
    # Not used anymore; we stub extraction instead to avoid PDF::Reader errors
    file = StringIO.new('')
    import.pdf_file.attach(io: file, filename: 'blank.pdf', content_type: 'application/pdf')
  end
end
