# frozen_string_literal: true

require 'test_helper'

class WebMenuSourceImportJobTest < ActiveSupport::TestCase
  def build_import
    ocr_menu_imports(:pending_import)
  end

  def build_html_source(import)
    MenuSource.create!(
      source_url: 'https://example.com/menu',
      source_type: :html,
      status: :active,
      restaurant: import.restaurant,
    )
  end

  test 'does nothing when import not found' do
    assert_nothing_raised do
      WebMenuSourceImportJob.new.perform(ocr_menu_import_id: -999_999, menu_source_id: 1)
    end
  end

  test 'marks import as failed when menu_source not found' do
    import = build_import
    WebMenuSourceImportJob.new.perform(ocr_menu_import_id: import.id, menu_source_id: -999_999)

    import.reload
    assert_equal 'failed', import.status
    assert import.error_message.present?
  end

  test 'marks import as failed when menu_source is not html type' do
    import = build_import
    pdf_source = MenuSource.create!(
      source_url: 'https://example.com/menu.pdf',
      source_type: :pdf,
      status: :active,
      restaurant: import.restaurant,
    )

    WebMenuSourceImportJob.new.perform(
      ocr_menu_import_id: import.id,
      menu_source_id: pdf_source.id,
    )

    import.reload
    assert_equal 'failed', import.status
  end

  test 'marks import as failed when scraper returns blank menu_text' do
    import = build_import
    source = build_html_source(import)

    fake_scraper = Object.new
    fake_scraper.define_singleton_method(:scrape) { |_pages| { menu_text: '', source_urls: [] } }

    MenuDiscovery::WebMenuScraper.stub(:new, fake_scraper) do
      WebMenuSourceImportJob.new.perform(
        ocr_menu_import_id: import.id,
        menu_source_id: source.id,
      )
    end

    import.reload
    assert_equal 'failed', import.status
  end

  test 'does not raise when processor completes successfully' do
    import = build_import
    source = build_html_source(import)

    fake_scraper = Object.new
    fake_scraper.define_singleton_method(:scrape) do |_pages|
      { menu_text: 'Burger $12', source_urls: ['https://example.com/menu'] }
    end

    fake_processor = Object.new
    fake_processor.define_singleton_method(:process) { |**_kwargs| nil }

    MenuDiscovery::WebMenuScraper.stub(:new, fake_scraper) do
      WebMenuProcessor.stub(:new, fake_processor) do
        import.stub(:process!, nil) do
          import.stub(:complete!, nil) do
            assert_nothing_raised do
              WebMenuSourceImportJob.new.perform(
                ocr_menu_import_id: import.id,
                menu_source_id: source.id,
              )
            end
          end
        end
      end
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      WebMenuSourceImportJob.perform_later(ocr_menu_import_id: 1, menu_source_id: 1)
    end
  end
end
