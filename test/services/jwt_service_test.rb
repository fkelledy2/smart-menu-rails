require 'test_helper'

class JwtServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @valid_payload = { user_id: @user.id, email: @user.email }
  end

  test 'should encode payload with default expiration' do
    token = JwtService.encode(@valid_payload)

    assert_not_nil token
    assert_instance_of String, token
    assert token.length.positive?
  end

  test 'should encode payload with custom expiration' do
    custom_exp = 1.hour.from_now
    token = JwtService.encode(@valid_payload, custom_exp)

    decoded = JWT.decode(token, JwtService::SECRET_KEY)[0]
    assert_equal custom_exp.to_i, decoded['exp']
  end

  test 'should decode valid token' do
    token = JwtService.encode(@valid_payload)
    decoded = JwtService.decode(token)

    assert_not_nil decoded
    assert_instance_of ActiveSupport::HashWithIndifferentAccess, decoded
    assert_equal @valid_payload[:user_id], decoded[:user_id]
    assert_equal @valid_payload[:email], decoded[:email]
    assert decoded[:exp].present?
  end

  test 'should return nil for invalid token' do
    invalid_token = 'invalid.token.here'
    decoded = JwtService.decode(invalid_token)

    assert_nil decoded
  end

  test 'should return nil for expired token' do
    expired_payload = @valid_payload.merge(exp: 1.hour.ago.to_i)
    token = JWT.encode(expired_payload, JwtService::SECRET_KEY)

    decoded = JwtService.decode(token)
    assert_nil decoded
  end

  test 'should generate token for user' do
    token = JwtService.generate_token_for_user(@user)

    assert_not_nil token
    assert_instance_of String, token

    # Verify token contains correct user data
    decoded = JwtService.decode(token)
    assert_equal @user.id, decoded[:user_id]
    assert_equal @user.email, decoded[:email]
    assert decoded[:iat].present?
  end

  test 'should retrieve user from valid token' do
    token = JwtService.generate_token_for_user(@user)
    retrieved_user = JwtService.user_from_token(token)

    assert_not_nil retrieved_user
    assert_equal @user.id, retrieved_user.id
    assert_equal @user.email, retrieved_user.email
  end

  test 'should return nil for nil token' do
    user = JwtService.user_from_token(nil)
    assert_nil user
  end

  test 'should return nil for invalid token in user_from_token' do
    user = JwtService.user_from_token('invalid.token')
    assert_nil user
  end

  test 'should return nil for token with non-existent user' do
    payload = { user_id: 99999, email: 'nonexistent@example.com' }
    token = JwtService.encode(payload)

    user = JwtService.user_from_token(token)
    assert_nil user
  end

  test 'should handle JWT decode errors gracefully' do
    # Mock JWT.decode to raise an error
    JWT.stub :decode, ->(_token, _key) { raise JWT::DecodeError, 'Test error' } do
      decoded = JwtService.decode('any_token')
      assert_nil decoded
    end
  end

  test 'should use Rails secret key base' do
    assert_equal Rails.application.secret_key_base, JwtService::SECRET_KEY
  end

  test 'should set expiration in payload' do
    custom_exp = 2.hours.from_now
    token = JwtService.encode({ test: 'data' }, custom_exp)

    decoded = JWT.decode(token, JwtService::SECRET_KEY)[0]
    assert_equal custom_exp.to_i, decoded['exp']
  end

  test 'should handle ActiveRecord::RecordNotFound in user_from_token' do
    # Create a token with valid format but non-existent user
    payload = { user_id: 99999, email: 'test@example.com' }
    token = JwtService.encode(payload)

    # This should return nil, not raise an exception
    user = JwtService.user_from_token(token)
    assert_nil user
  end

  test 'should include issued at timestamp in generated token' do
    freeze_time = Time.current

    Time.stub :current, freeze_time do
      token = JwtService.generate_token_for_user(@user)
      decoded = JwtService.decode(token)

      assert_equal freeze_time.to_i, decoded[:iat]
    end
  end
end
