class WhiskyHunterClient < ExternalApiClient
  def search_by_name(name)
    q = name.to_s.strip
    raise ArgumentError, 'name required' if q == ''

    path = ENV.fetch('WHISKY_HUNTER_SEARCH_PATH', '/search')
    get(path, query: { q: q })
  end

  protected

  def default_config
    super.merge(
      base_uri: ENV.fetch('WHISKY_HUNTER_BASE_URI', nil),
      api_key: ENV.fetch('WHISKY_HUNTER_API_KEY', nil),
      timeout: 30.seconds,
      max_retries: 2,
    )
  end
end
