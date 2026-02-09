require 'test_helper'

class Payments::ImpersonationRiskGateTest < ActionController::TestCase
  tests ApplicationController

  setup do
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    @controller.request = @request
    @controller.response = @response
  end

  test 'payments endpoints are forbidden for JSON while impersonating (unit-style)' do
    @request.headers['ACCEPT'] = 'application/json'

    rendered = []

    @controller.stub(:impersonating_user?, true) do
      @controller.stub(:controller_path, 'payments/subscriptions') do
        @controller.stub(:render, ->(**args) { rendered << args }) do
          @controller.block_high_risk_actions_when_impersonating
        end
      end
    end

    assert_equal 1, rendered.length
    assert_equal({ error: 'Action not allowed while impersonating' }, rendered[0][:json])
    assert_equal :forbidden, rendered[0][:status]
  end

  test 'non-high-risk endpoints are not blocked by guard' do
    @request.headers['ACCEPT'] = 'application/json'

    @controller.stub(:impersonating_user?, true) do
      @controller.stub(:controller_path, 'restaurants') do
        @controller.block_high_risk_actions_when_impersonating
      end
    end

    assert_equal 200, @response.status
    assert_equal '', @response.body
  end
end
