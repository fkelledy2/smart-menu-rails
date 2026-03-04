# frozen_string_literal: true

require 'test_helper'

module Payments
  module Providers
    class SquareHttpClientTest < ActiveSupport::TestCase
      def setup
        @client = SquareHttpClient.new(access_token: 'test-token', environment: 'sandbox')
      end

      # --- Initialization ---

      test 'initializes with sandbox environment' do
        client = SquareHttpClient.new(access_token: 'tok', environment: 'sandbox')
        assert_instance_of SquareHttpClient, client
      end

      test 'initializes with production environment' do
        client = SquareHttpClient.new(access_token: 'tok', environment: 'production')
        assert_instance_of SquareHttpClient, client
      end

      # --- Successful responses ---

      test 'get returns parsed response on success' do
        fake_response = mock_response(200, { 'locations' => [] })

        HTTParty.stub :send, fake_response do
          result = @client.get('/locations')
          assert_equal({ 'locations' => [] }, result)
        end
      end

      test 'post returns parsed response on success' do
        fake_response = mock_response(200, { 'payment' => { 'id' => 'pay_123' } })

        HTTParty.stub :send, fake_response do
          result = @client.post('/payments', body: { amount: 1000 })
          assert_equal 'pay_123', result.dig('payment', 'id')
        end
      end

      # --- Error responses ---

      test 'raises SquareApiError on 401' do
        fake_response = mock_response(401, {
          'errors' => [{ 'category' => 'AUTHENTICATION_ERROR', 'code' => 'UNAUTHORIZED', 'detail' => 'Access token is invalid' }],
        })

        HTTParty.stub :send, fake_response do
          error = assert_raises(SquareHttpClient::SquareApiError) { @client.get('/locations') }
          assert_equal 401, error.status_code
          assert_equal 'AUTHENTICATION_ERROR', error.category
          assert_equal 'Access token is invalid', error.message
        end
      end

      test 'raises SquareApiError on 500' do
        fake_response = mock_response(500, {
          'errors' => [{ 'category' => 'API_ERROR', 'code' => 'INTERNAL_SERVER_ERROR', 'detail' => 'Internal error' }],
        })

        HTTParty.stub :send, fake_response do
          error = assert_raises(SquareHttpClient::SquareApiError) { @client.post('/payments', body: {}) }
          assert_equal 500, error.status_code
          assert_equal 'API_ERROR', error.category
        end
      end

      test 'SquareApiError exposes multiple errors' do
        fake_response = mock_response(400, {
          'errors' => [
            { 'category' => 'INVALID_REQUEST_ERROR', 'code' => 'MISSING_REQUIRED_PARAMETER', 'detail' => 'Missing field' },
            { 'category' => 'INVALID_REQUEST_ERROR', 'code' => 'INVALID_VALUE', 'detail' => 'Bad value' },
          ],
        })

        HTTParty.stub :send, fake_response do
          error = assert_raises(SquareHttpClient::SquareApiError) { @client.post('/payments', body: {}) }
          assert_equal 2, error.errors.length
        end
      end

      private

      # Builds a mock HTTParty response object
      def mock_response(code, parsed_body)
        response = Minitest::Mock.new
        response.expect :success?, code >= 200 && code < 300
        response.expect :parsed_response, parsed_body
        unless code >= 200 && code < 300
          response.expect :code, code
          response.expect :code, code
        end
        response
      end
    end
  end
end
