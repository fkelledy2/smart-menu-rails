# frozen_string_literal: true

require 'test_helper'

class TwoFactor::SetupServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = TwoFactor::SetupService.new(@user)
  end

  test 'returns a secret key' do
    result = @service.call
    assert result[:secret].present?
    assert result[:secret].length >= 16
  end

  test 'returns a valid QR SVG' do
    result = @service.call
    assert result[:qr_svg].present?
    assert_includes result[:qr_svg], '<svg'
  end

  test 'returns a provisioning URI with the user email' do
    result = @service.call
    assert result[:provisioning_uri].present?
    assert_includes result[:provisioning_uri], URI.encode_www_form_component(@user.email)
  end

  test 'returns a provisioning URI with the issuer' do
    result = @service.call
    assert_includes result[:provisioning_uri], 'mellow.menu'
  end

  test 'generates a different secret on each call' do
    result1 = @service.call
    result2 = @service.call
    assert_not_equal result1[:secret], result2[:secret]
  end
end
