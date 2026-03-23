require 'test_helper'

class AvatarHelperTest < ActionView::TestCase
  test 'avatar_path returns gravatar URL when user has email but no avatar' do
    user = users(:one)
    result = avatar_path(user)
    assert_kind_of String, result
    assert_includes result, 'gravatar.com'
  end

  test 'avatar_path returns default URL when object has no email' do
    obj = OpenStruct.new
    result = avatar_path(obj)
    assert_includes result, 'gravatar.com'
    assert_includes result, '00000000000000000000000000000000'
  end

  test 'avatar_path uses custom size' do
    user = users(:one)
    result = avatar_path(user, size: 50)
    assert_includes result.to_s, 's=50'
  end

  test 'avatar_path uses default size of 180' do
    user = users(:one)
    result = avatar_path(user)
    assert_includes result.to_s, 's=180'
  end

  test 'avatar_path handles email for gravatar hash' do
    user = users(:one)
    expected_hash = Digest::MD5.hexdigest(user.email.downcase)
    result = avatar_path(user)
    assert_includes result.to_s, expected_hash
  end
end
