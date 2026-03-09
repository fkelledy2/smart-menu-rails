require 'test_helper'

class CodeQualityRakeTest < ActiveSupport::TestCase
  setup do
    @source = Rails.root.join('lib', 'tasks', 'code_quality.rake').read
  end

  test 'code_quality:all task exists' do
    assert_match(/task\s+all:\s*%i\[rubocop brakeman bundle_audit\]/, @source)
  end

  test 'code_quality:rubocop task exists' do
    assert_match(/task\s+rubocop:\s*:environment/, @source)
  end

  test 'code_quality:rubocop_check task exists' do
    assert_match(/task\s+rubocop_check:\s*:environment/, @source)
  end

  test 'code_quality:brakeman task exists' do
    assert_match(/task\s+brakeman:\s*:environment/, @source)
  end

  test 'code_quality:bundle_audit task exists' do
    assert_match(/task\s+bundle_audit:\s*:environment/, @source)
  end

  test 'code_quality:report task exists' do
    assert_match(/task\s+report:\s*:environment/, @source)
  end

  test 'code_quality:ci task exists' do
    assert_match(/task\s+ci:\s*:environment/, @source)
  end

  test 'code_quality:all has correct dependencies' do
    assert_match(/task\s+all:\s*%i\[rubocop brakeman bundle_audit\]/, @source)
  end
end
