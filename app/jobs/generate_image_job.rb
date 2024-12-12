require 'sidekiq'

class GenerateImageJob
  include Sidekiq::Job

  def perform(genimage_id)
    @genimage = Genimage.find(genimage_id)
    if( @genimage )
        if( @genimage.menuitem != nil )
            response = generate_image(@genimage.menuitem.description,'512x512')
            puts response
            if response.success?
              seed = response['created']
              image_url = response['data'][0]['url']
              downloaded_image = URI.parse(image_url).open
              @genimage.name = seed
              @genimage.save
              @genimage.menuitem.image = downloaded_image
              @genimage.menuitem.save
            else
              puts 'error'
            end
        end
    end
  end

  private

  def generate_image(prompt, size)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = { prompt: prompt, n: 1, size: size }.to_json
        HTTParty.post(
          'https://api.openai.com/v1/images/generations',
          headers: headers,
          body: body
        )
  end
end
