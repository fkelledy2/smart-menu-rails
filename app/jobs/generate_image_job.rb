require 'sidekiq'

class GenerateImageJob
  include Sidekiq::Worker
  sidekiq_options queue: "limited"

  extend Limiter::Mixin
  limit_method :expensive_api_call, rate: 4, interval: 60, balanced: true

  def perform(genimage_id)
    expensive_api_call(genimage_id)
  end

  private

  def expensive_api_call(genimage_id)
    @genimage = Genimage.find(genimage_id)
    if( @genimage )
        if( @genimage.menuitem != nil )
            prompt = 'generate an image of '
            prompt += @genimage.menuitem.name + ' : '
            prompt += @genimage.menuitem.description + ' '
            if( @genimage.menuitem.menusection.menu.restaurant && @genimage.menuitem.menusection.menu.restaurant.imagecontext )
                prompt += 'The restaurant is a '
                prompt += @genimage.menuitem.menusection.menu.restaurant.imagecontext
            end
            if( @genimage.menuitem.menusection.menu && @genimage.menuitem.menusection.menu.imagecontext )
                prompt += 'The table setting is '
                prompt += @genimage.menuitem.menusection.menu.imagecontext
            end
            prompt += ', showcasing the meal as the centerpiece. '
            prompt += 'The focus is 75% on the tableware, capturing every detail of the foods presentation, '
            prompt += 'while the background is blurred to emphasize the dish. '

#             if( @genimage.name )
#                 prompt += 'use seed: '+@genimage.name
#             end

            response = generate_image(prompt, 1, '256x256')
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

  def generate_image(prompt, number, size)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = { prompt: prompt, n: number, size: size }.to_json
        puts body
        HTTParty.post(
          'https://api.openai.com/v1/images/generations',
          headers: headers,
          body: body
        )
  end

  def ask_question(prompt)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = {
            messages: [{ role: 'user', content: prompt }],
            model: 'gpt-3.5-turbo'
        }.to_json
        HTTParty.post(
          'https://api.openai.com/v1/chat/completions',
          headers: headers,
          body: body
        )
  end

end

# https://oaidalleapiprodscus.blob.core.windows.net/private/org-LzD1hb4w3WMelt7pEVnBYP2R/user-GjMFpkTLTGr1PCr06hyZx5Yj/img-8ieCFhLNUGlJ9P2621AHwQ7m.png?
# st=2025-01-11T15%3A42%3A19Z&se=2025-01-11T17%3A42%3A19Z&
# sp=r&sv=2024-08-04&sr=b&rscd=inline&rsct=image/png&
# skoid=d505667d-d6c1-4a0a-bac7-5c84a87759f8&
# sktid=a48cca56-e6da-484e-a814-9c849652bcb3
# &skt=2025-01-11T00%3A19%3A06Z
# &ske=2025-01-12T00%3A19%3A06Z&sks=b
# &skv=2024-08-04&
# sig=d0rop2TSBSGJlSMWhl/XkqgDocSrmicOswAq%2BtpaRO4%3D"