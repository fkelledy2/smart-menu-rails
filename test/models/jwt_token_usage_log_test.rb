# frozen_string_literal: true

require 'test_helper'

class JwtTokenUsageLogTest < ActiveSupport::TestCase
  def setup
    @token = admin_jwt_tokens(:active_token)
  end

  test 'belongs to jwt_token' do
    log = jwt_token_usage_logs(:log_one)
    assert_equal @token, log.jwt_token
  end

  test 'valid with required attributes' do
    log = JwtTokenUsageLog.new(
      jwt_token: @token,
      endpoint: '/api/v1/test',
      http_method: 'GET',
      ip_address: '127.0.0.1',
      response_status: 200,
    )
    assert log.valid?
  end

  test 'invalid without endpoint' do
    log = JwtTokenUsageLog.new(jwt_token: @token, http_method: 'GET', response_status: 200)
    assert log.invalid?
  end

  test 'invalid without http_method' do
    log = JwtTokenUsageLog.new(jwt_token: @token, endpoint: '/api/v1/test', response_status: 200)
    assert log.invalid?
  end

  test 'invalid without response_status' do
    log = JwtTokenUsageLog.new(jwt_token: @token, endpoint: '/api/v1/test', http_method: 'GET')
    assert log.invalid?
  end

  test 'purgeable scope returns logs older than 90 days' do
    old_log = jwt_token_usage_logs(:log_one)
    old_log.update_column(:created_at, 91.days.ago)

    assert_includes JwtTokenUsageLog.purgeable, old_log
    assert_not_includes JwtTokenUsageLog.purgeable, jwt_token_usage_logs(:log_two)
  end

  test 'recent scope orders by created_at descending' do
    logs = JwtTokenUsageLog.for_token(@token.id).recent
    assert_operator logs.first.created_at, :>=, logs.last.created_at
  end
end
