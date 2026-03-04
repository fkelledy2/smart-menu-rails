# frozen_string_literal: true

module Payments
  module Providers
    # Thin HTTParty wrapper for Square API calls.
    # Handles authentication, versioning, JSON parsing, and typed errors.
    class SquareHttpClient
      class SquareApiError < StandardError
        attr_reader :status_code, :errors, :category

        def initialize(message, status_code: nil, errors: [], category: nil)
          @status_code = status_code
          @errors = errors
          @category = category
          super(message)
        end
      end

      def initialize(access_token:, environment: nil)
        @access_token = access_token
        @environment = environment || SquareConfig.environment
        @base_url = @environment == 'sandbox' \
          ? 'https://connect.squareupsandbox.com/v2' \
          : 'https://connect.squareup.com/v2'
      end

      def get(path, query: {})
        execute(:get, path, query: query)
      end

      def post(path, body: {})
        execute(:post, path, body: body)
      end

      def put(path, body: {})
        execute(:put, path, body: body)
      end

      def delete(path, body: {})
        execute(:delete, path, body: body)
      end

      private

      def execute(method, path, query: {}, body: {})
        url = "#{@base_url}#{path}"
        options = { headers: default_headers, timeout: 15 }
        options[:query] = query if query.present?
        options[:body] = body.to_json if body.present? && method != :get

        response = HTTParty.send(method, url, **options)
        handle_response(response)
      end

      def default_headers
        {
          'Authorization' => "Bearer #{@access_token}",
          'Square-Version' => SquareConfig.api_version,
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
        }
      end

      def handle_response(response)
        parsed = response.parsed_response
        return parsed if response.success?

        errors = parsed.is_a?(Hash) ? parsed.dig('errors') || [] : []
        first = errors.first || {}
        raise SquareApiError.new(
          first['detail'] || "Square API error (#{response.code})",
          status_code: response.code,
          errors: errors,
          category: first['category'],
        )
      end
    end
  end
end
