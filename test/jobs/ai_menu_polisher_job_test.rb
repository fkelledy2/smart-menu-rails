# frozen_string_literal: true

require 'test_helper'

class AiMenuPolisherJobTest < ActiveSupport::TestCase
  def setup
    @job = AiMenuPolisherJob.new
  end

  test 'does nothing when menu does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  end

  test 'normalize_title titleizes text' do
    assert_equal 'Grilled Chicken', @job.send(:normalize_title, 'grilled chicken')
  end

  test 'normalize_title strips extra whitespace' do
    assert_equal 'Fish And Chips', @job.send(:normalize_title, '  fish  and  chips  ')
  end

  test 'normalize_title returns empty string for blank' do
    assert_equal '', @job.send(:normalize_title, '')
    assert_equal '', @job.send(:normalize_title, nil)
  end

  test 'normalize_sentence capitalizes first letter' do
    assert_equal 'A rich broth.', @job.send(:normalize_sentence, 'a rich broth.')
  end

  test 'normalize_sentence strips extra whitespace' do
    assert_equal 'Tender and juicy.', @job.send(:normalize_sentence, '  Tender  and  juicy.  ')
  end

  test 'normalize_sentence returns empty string for blank' do
    assert_equal '', @job.send(:normalize_sentence, '')
    assert_equal '', @job.send(:normalize_sentence, nil)
  end

  test 'texts_equal? returns true for same text ignoring case' do
    assert @job.send(:texts_equal?, 'Burger', 'burger')
    assert @job.send(:texts_equal?, 'BURGER', 'Burger')
  end

  test 'texts_equal? returns true for same text ignoring whitespace' do
    assert @job.send(:texts_equal?, ' Burger ', 'Burger')
  end

  test 'texts_equal? returns false for different text' do
    assert_not @job.send(:texts_equal?, 'Burger', 'Pizza')
  end

  test 'locale_to_language maps IT to Italian' do
    assert_equal 'Italian', @job.send(:locale_to_language, 'it')
    assert_equal 'Italian', @job.send(:locale_to_language, 'it-IT')
  end

  test 'locale_to_language maps FR to French' do
    assert_equal 'French', @job.send(:locale_to_language, 'fr')
  end

  test 'locale_to_language maps ES to Spanish' do
    assert_equal 'Spanish', @job.send(:locale_to_language, 'es')
  end

  test 'locale_to_language maps PT to Portuguese' do
    assert_equal 'Portuguese', @job.send(:locale_to_language, 'pt')
  end

  test 'locale_to_language defaults to English' do
    assert_equal 'English', @job.send(:locale_to_language, 'en')
    assert_equal 'English', @job.send(:locale_to_language, 'de')
    assert_equal 'English', @job.send(:locale_to_language, nil)
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      AiMenuPolisherJob.perform_async(-999_999)
    end
  end
end
