# Base class for external API clients with consistent error handling, retries, and timeouts
class ExternalApiClient
  include HTTParty

  # Custom exceptions
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ApiError < Error; end
  class TimeoutError < Error; end
  class RateLimitError < Error; end
  class AuthenticationError < Error; end

  # Default configuration
  DEFAULT_TIMEOUT = 30.seconds
  DEFAULT_RETRIES = 3
  DEFAULT_RETRY_DELAY = 1.second
  DEFAULT_BACKOFF_MULTIPLIER = 2

  attr_reader :config

  def initialize(config = {})
    @config = default_config.merge(config)
    validate_config!
    setup_httparty_options
  end

  # Make a request with automatic retries and error handling
  # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
  # @param path [String] API endpoint path
  # @param options [Hash] Request options (body, headers, etc.)
  # @return [HTTParty::Response] Response object
  def request(method, path, options = {})
    retries = 0
    delay = config[:retry_delay]

    begin
      response = with_timeout do
        self.class.public_send(method, path, build_request_options(options))
      end

      handle_response(response)
    rescue Net::TimeoutError, Net::ReadTimeout => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue *retryable_errors => e
      retries += 1
      unless retries <= config[:max_retries]
        raise ApiError, "API request failed after #{config[:max_retries]} retries: #{e.message}"
      end

      Rails.logger.warn "API request failed (attempt #{retries}/#{config[:max_retries]}): #{e.message}"
      sleep(delay)
      delay *= config[:backoff_multiplier]
      retry
    end
  end

  # GET request
  def get(path, options = {})
    request(:get, path, options)
  end

  # POST request
  def post(path, options = {})
    request(:post, path, options)
  end

  # PUT request
  def put(path, options = {})
    request(:put, path, options)
  end

  # DELETE request
  def delete(path, options = {})
    request(:delete, path, options)
  end

  # Check if the API is healthy
  # @return [Boolean] True if API is responding
  def healthy?
    health_check_endpoint = config[:health_check_endpoint]
    return true unless health_check_endpoint

    begin
      response = get(health_check_endpoint)
      response.success?
    rescue Error
      false
    end
  end

  protected

  # Override in subclasses to provide specific configuration
  def default_config
    {
      timeout: DEFAULT_TIMEOUT,
      max_retries: DEFAULT_RETRIES,
      retry_delay: DEFAULT_RETRY_DELAY,
      backoff_multiplier: DEFAULT_BACKOFF_MULTIPLIER,
      base_uri: nil,
      api_key: nil,
      headers: {},
      health_check_endpoint: nil,
    }
  end

  # Override in subclasses to add custom validation
  def validate_config!
    raise ConfigurationError, 'base_uri is required' unless config[:base_uri]
  end

  # Override in subclasses to handle specific response patterns
  def handle_response(response)
    case response.code
    when 200..299
      response
    when 401, 403
      raise AuthenticationError, "Authentication failed: #{response.body}"
    when 429
      raise RateLimitError, "Rate limit exceeded: #{response.body}"
    when 400..499
      raise ApiError, "Client error (#{response.code}): #{response.body}"
    when 500..599
      raise ApiError, "Server error (#{response.code}): #{response.body}"
    else
      raise ApiError, "Unexpected response (#{response.code}): #{response.body}"
    end
  end

  # Override in subclasses to specify which errors should trigger retries
  def retryable_errors
    [
      Net::ReadTimeout,
      Net::OpenTimeout,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      SocketError,
    ]
  end

  private

  def setup_httparty_options
    self.class.base_uri(config[:base_uri])
    self.class.default_timeout(config[:timeout])

    if config[:headers].any?
      self.class.headers(config[:headers])
    end
  end

  def build_request_options(options)
    request_options = options.dup

    # Add authentication if configured
    if config[:api_key]
      request_options[:headers] ||= {}
      request_options[:headers].merge!(auth_headers)
    end

    # Add default headers
    request_options[:headers] ||= {}
    request_options[:headers]['User-Agent'] ||= 'SmartMenu/1.0'
    request_options[:headers]['Accept'] ||= 'application/json'
    request_options[:headers]['Content-Type'] ||= 'application/json' if %i[post put patch].include?(options[:method])

    request_options
  end

  # Override in subclasses to provide authentication headers
  def auth_headers
    { 'Authorization' => "Bearer #{config[:api_key]}" }
  end

  def with_timeout(&)
    Timeout.timeout(config[:timeout], &)
  end
end
