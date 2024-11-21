# config/initializers/chatgpt.rb

require 'chatgpt/client'
client = ChatGPT::Client.new(Rails.application.credentials.openai_api_key)

# response = client.chat([
#   { role: "user", content: "What is Ruby?" }
# ])
# puts response.dig("choices", 0, "message", "content")
