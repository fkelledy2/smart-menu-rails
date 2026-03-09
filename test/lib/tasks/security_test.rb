require 'test_helper'

class SecurityRakeTest < ActiveSupport::TestCase
  setup do
    @source = Rails.root.join('lib', 'tasks', 'security.rake').read
  end

  test 'security:all task exists' do
    assert_match(/task\s+all:\s*%i\[brakeman bundle_audit secrets_scan\]/, @source)
  end

  test 'security:brakeman task exists' do
    assert_match(/task\s+brakeman:\s*:environment/, @source)
  end

  test 'security:bundle_audit task exists' do
    assert_match(/task\s+bundle_audit:\s*:environment/, @source)
  end

  test 'security:secrets_scan task exists' do
    assert_match(/task\s+secrets_scan:\s*:environment/, @source)
  end

  test 'security:report task exists' do
    assert_match(/task\s+report:\s*:environment/, @source)
  end

  test 'security:ci task exists' do
    assert_match(/task\s+ci:\s*:environment/, @source)
  end

  test 'security:all has correct dependencies' do
    assert_match(/task\s+all:\s*%i\[brakeman bundle_audit secrets_scan\]/, @source)
  end
end
