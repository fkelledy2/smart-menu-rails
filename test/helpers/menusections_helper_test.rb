require 'test_helper'

class MenusectionsHelperTest < ActionView::TestCase
  test 'format_time_range returns html with clock icons' do
    result = format_time_range(9, 30, 17, 0)
    assert_includes result, 'bi-clock'
    assert_includes result, '09:30'
    assert_includes result, '17:00'
  end

  test 'format_time_range zero-pads hours and minutes' do
    result = format_time_range(8, 5, 9, 0)
    assert_includes result, '08:05'
    assert_includes result, '09:00'
  end

  test 'format_time_range includes en dash separator' do
    result = format_time_range(10, 0, 22, 0)
    assert_includes result, '–'
  end

  test 'format_time_range handles midnight' do
    result = format_time_range(0, 0, 0, 0)
    assert_includes result, '00:00'
  end
end
