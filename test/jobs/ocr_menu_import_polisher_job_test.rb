# frozen_string_literal: true

require 'test_helper'

class OcrMenuImportPolisherJobTest < ActiveSupport::TestCase
  def setup
    @job = OcrMenuImportPolisherJob.new
  end

  test 'does nothing when import does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  end

  test 'normalize_title titleizes text' do
    assert_equal 'Caesar Salad', @job.send(:normalize_title, 'caesar salad')
  end

  test 'normalize_title strips extra whitespace' do
    assert_equal 'Fish And Chips', @job.send(:normalize_title, '  fish  and  chips  ')
  end

  test 'normalize_title returns empty string for blank' do
    assert_equal '', @job.send(:normalize_title, '')
    assert_equal '', @job.send(:normalize_title, nil)
  end

  test 'normalize_sentence capitalizes first letter only' do
    assert_equal 'Slow-cooked lamb shank.', @job.send(:normalize_sentence, 'slow-cooked lamb shank.')
  end

  test 'normalize_sentence strips extra whitespace' do
    assert_equal 'Crispy and golden.', @job.send(:normalize_sentence, '  Crispy  and  golden.  ')
  end

  test 'normalize_sentence returns empty string for blank' do
    assert_equal '', @job.send(:normalize_sentence, '')
    assert_equal '', @job.send(:normalize_sentence, nil)
  end

  test 'texts_equal? returns true for same text ignoring case and whitespace' do
    assert @job.send(:texts_equal?, 'Pasta', 'pasta')
    assert @job.send(:texts_equal?, ' Pasta ', 'Pasta')
  end

  test 'texts_equal? returns false for different text' do
    assert_not @job.send(:texts_equal?, 'Pasta', 'Pizza')
  end

  test 'locale_to_language maps known locales' do
    assert_equal 'Italian', @job.send(:locale_to_language, 'it')
    assert_equal 'French', @job.send(:locale_to_language, 'fr')
    assert_equal 'Spanish', @job.send(:locale_to_language, 'es')
    assert_equal 'Portuguese', @job.send(:locale_to_language, 'pt')
    assert_equal 'English', @job.send(:locale_to_language, 'en')
  end

  test 'locale_to_language handles locale with region subtag' do
    assert_equal 'Italian', @job.send(:locale_to_language, 'it-IT')
    assert_equal 'French', @job.send(:locale_to_language, 'fr-FR')
  end

  test 'locale_to_language defaults to English for unknown locale' do
    assert_equal 'English', @job.send(:locale_to_language, 'de')
    assert_equal 'English', @job.send(:locale_to_language, nil)
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      OcrMenuImportPolisherJob.perform_async(-999_999)
    end
  end
end
