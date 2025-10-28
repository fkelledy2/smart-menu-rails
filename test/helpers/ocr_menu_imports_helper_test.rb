require 'test_helper'

class OcrMenuImportsHelperTest < ActionView::TestCase
  # === STATUS BADGE CLASSES TESTS ===

  test 'should return correct classes for pending status' do
    result = status_badge_classes(:pending)
    assert_includes result, 'bg-yellow-100 text-yellow-800'
  end

  test 'should return correct classes for processing status' do
    result = status_badge_classes(:processing)
    assert_includes result, 'bg-blue-100 text-blue-800 animate-pulse'
  end

  test 'should return correct classes for completed status' do
    result = status_badge_classes(:completed)
    assert_includes result, 'bg-green-100 text-green-800'
  end

  test 'should return correct classes for failed status' do
    result = status_badge_classes(:failed)
    assert_includes result, 'bg-red-100 text-red-800'
  end

  test 'should return default classes for unknown status' do
    result = status_badge_classes(:unknown)
    assert_includes result, 'bg-gray-100 text-gray-800'
  end

  # === STATUS BADGE TESTS ===

  test 'should create status badge with correct content' do
    result = status_badge('pending')
    assert_includes result, 'Pending'
    assert_includes result, 'bg-yellow-100'
  end

  # === HUMAN FILE SIZE TESTS ===

  test 'should return 0 B for zero bytes' do
    assert_equal '0 B', human_file_size(0)
    assert_equal '0 B', human_file_size(nil)
  end

  test 'should format file sizes correctly' do
    assert_includes human_file_size(1024), 'KB'
    assert_includes human_file_size(1_048_576), 'MB'
  end
end
