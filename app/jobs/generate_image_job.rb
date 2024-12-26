require 'sidekiq'

class GenerateImageJob
  include Sidekiq::Job

  def perform(genimage_id)
    @genimage = Genimage.find(genimage_id)
    if( @genimage )
        if( @genimage.menuitem != nil )
            prompt = ''
            if( @genimage.menuitem.menusection.menu && @genimage.menuitem.menusection.menu.imagecontext )
                prompt += @genimage.menuitem.menusection.menu.imagecontext+' with '
            end
            prompt += @genimage.menuitem.description
            if( @genimage.menuitem.menusection.menu.restaurant && @genimage.menuitem.menusection.menu.restaurant.imagecontext )
                prompt += ' set on a '+@genimage.menuitem.menusection.menu.restaurant.imagecontext
            end
            prompt +=' The image is captured at an angle of 33 degrees, emphasizing the appetizing presentation, with the background softly blurred to keep focus on the dish. '
            if( @genimage.menuitem.menusection.menu.restaurant.genid )
                prompt += 'use seed_id: '+@genimage.menuitem.menusection.menu.restaurant.genid
            end

            puts prompt
            response = generate_image(prompt, 1, '512x512')
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

  def generate_image(prompt, number, size)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = { prompt: prompt, n: number, size: size }.to_json
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
