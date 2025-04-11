 require "deepl"

DeepL.configure do |config|
  config.auth_key = '9079cde6-1153-4f72-a220-306de587c58e:fx'
  config.host = 'https://api-free.deepl.com' # Default value is 'https://api.deepl.com'
  config.version = 'v1' # Default value is 'v2'
end
