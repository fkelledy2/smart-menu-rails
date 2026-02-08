# OpenAI API client for image generation and other AI services
class OpenaiClient < ExternalApiClient
  # OpenAI specific exceptions
  class ImageGenerationError < ApiError; end
  class InvalidPromptError < Error; end
  class ModelNotFoundError < Error; end
  class QuotaExceededError < RateLimitError; end

  # Image generation models
  IMAGE_MODELS = {
    'dall-e-2' => { max_size: '1024x1024', sizes: %w[256x256 512x512 1024x1024] },
    'dall-e-3' => { max_size: '1792x1024', sizes: %w[1024x1024 1792x1024 1024x1792] },
  }.freeze

  # Generate images from text prompt
  # @param prompt [String] Text description of the image
  # @param n [Integer] Number of images to generate (1-10 for DALL-E 2, 1 for DALL-E 3)
  # @param size [String] Image size (e.g., '1024x1024')
  # @param model [String] Model to use ('dall-e-2' or 'dall-e-3')
  # @param quality [String] Image quality ('standard' or 'hd') - DALL-E 3 only
  # @return [Hash] Response with image URLs and metadata
  def generate_images(prompt, n: 1, size: '1024x1024', model: 'dall-e-3', quality: 'standard')
    validate_image_params!(prompt, n, size, model)

    body = {
      model: model,
      prompt: prompt,
      n: n,
      size: size,
      response_format: 'url',
    }

    # Add quality parameter for DALL-E 3
    body[:quality] = quality if model == 'dall-e-3'

    response = post('/images/generations', {
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' },
    })

    process_image_response(response)
  rescue ApiError => e
    handle_openai_error(e)
  end

  # Create image variations
  # @param image_path [String] Path to the source image
  # @param n [Integer] Number of variations to generate
  # @param size [String] Size of generated images
  # @return [Hash] Response with variation URLs
  def create_image_variations(image_path, n: 1, size: '1024x1024')
    validate_image_file!(image_path)

    body = {
      image: File.open(image_path, 'rb'),
      n: n,
      size: size,
      response_format: 'url',
    }

    response = post('/images/variations', {
      body: body,
      headers: {}, # Let HTTParty handle multipart
    })

    process_image_response(response)
  end

  # Edit an image with a prompt
  # @param image_path [String] Path to the source image
  # @param mask_path [String] Path to the mask image (optional)
  # @param prompt [String] Description of the desired edit
  # @param n [Integer] Number of edited images to generate
  # @param size [String] Size of generated images
  # @return [Hash] Response with edited image URLs
  def edit_image(image_path, prompt, mask_path: nil, n: 1, size: '1024x1024')
    validate_image_file!(image_path)
    validate_image_file!(mask_path) if mask_path

    body = {
      image: File.open(image_path, 'rb'),
      prompt: prompt,
      n: n,
      size: size,
      response_format: 'url',
    }

    body[:mask] = File.open(mask_path, 'rb') if mask_path

    response = post('/images/edits', {
      body: body,
      headers: {}, # Let HTTParty handle multipart
    })

    process_image_response(response)
  end

  # Get available models
  # @return [Array<Hash>] List of available models
  def models
    response = get('/models')
    response.parsed_response['data']
  end

  protected

  def default_config
    super.merge(
      base_uri: 'https://api.openai.com/v1',
      api_key: openai_api_key,
      timeout: 60.seconds, # Image generation can take longer
      max_retries: 2, # Fewer retries for expensive operations
    )
  end

  def validate_config!
    super
    raise ConfigurationError, 'OpenAI API key is required' unless config[:api_key]
  end

  def handle_response(response)
    case response.code
    when 400
      error_message = extract_error_message(response)
      raise QuotaExceededError, "OpenAI quota exceeded: #{error_message}" if error_message.include?('billing')

      raise ApiError, "Bad request: #{error_message}"

    when 429
      raise RateLimitError, 'OpenAI rate limit exceeded'
    else
      super
    end
  end

  private

  def openai_api_key
    Rails.application.credentials.openai_api_key || ENV.fetch('OPENAI_API_KEY', nil)
  end

  def validate_image_params!(prompt, n, size, model)
    raise InvalidPromptError, 'Prompt cannot be blank' if prompt.blank?
    raise InvalidPromptError, 'Prompt too long (max 1000 characters)' if prompt.length > 1000

    model_config = IMAGE_MODELS[model]
    raise ModelNotFoundError, "Unsupported model: #{model}" unless model_config

    unless model_config[:sizes].include?(size)
      raise InvalidPromptError, "Unsupported size #{size} for model #{model}"
    end

    max_n = model == 'dall-e-3' ? 1 : 10
    raise InvalidPromptError, "Invalid n value: #{n} (max #{max_n} for #{model})" if n < 1 || n > max_n
  end

  def validate_image_file!(file_path)
    return unless file_path

    raise InvalidPromptError, "Image file not found: #{file_path}" unless File.exist?(file_path)

    file_size = File.size(file_path)
    raise InvalidPromptError, 'Image file too large (max 4MB)' if file_size > 4.megabytes

    extension = File.extname(file_path).downcase
    allowed_extensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif']
    unless allowed_extensions.include?(extension)
      raise InvalidPromptError, "Unsupported image format: #{extension}"
    end
  end

  def process_image_response(response)
    data = response.parsed_response

    unless data['data']&.any?
      raise ImageGenerationError, 'No images generated'
    end

    {
      created: data['created'],
      data: data['data'].map do |image|
        {
          url: image['url'],
          revised_prompt: image['revised_prompt'],
        }
      end,
    }
  end

  def handle_openai_error(error)
    case error.message
    when /content policy/i
      raise InvalidPromptError, 'Prompt violates OpenAI content policy'
    when /billing/i, /quota/i
      raise QuotaExceededError, 'OpenAI quota or billing issue'
    else
      raise ImageGenerationError, "Image generation failed: #{error.message}"
    end
  end

  def extract_error_message(response)
    parsed = response.parsed_response
    parsed.dig('error', 'message') || response.body
  end

  def auth_headers
    { 'Authorization' => "Bearer #{config[:api_key]}" }
  end
end
