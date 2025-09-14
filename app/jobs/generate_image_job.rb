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
  @genimage = Genimage.find_by(id: genimage_id)
  unless @genimage
    Rails.logger.error "Genimage with ID #{genimage_id} not found"
    return
  end

  @menuitem = @genimage.menuitem
  unless @menuitem
    Rails.logger.error "Menuitem not found for Genimage #{genimage_id}"
    return
  end

  prompt = build_prompt
  response = generate_image(prompt, 1, '256x256')

  if response.success?
    seed = response['created']
    image_url = response['data'][0]['url']

    begin
      downloaded_image = URI.parse(image_url).open

      # Update genimage with seed
      @genimage.update(name: seed)

      # Attach the image to menuitem
      @menuitem.image = downloaded_image
      @menuitem.save!

      Rails.logger.info "Successfully generated and attached image for Menuitem #{@menuitem.id}"
    rescue StandardError => e
      Rails.logger.error "Error processing image for Genimage #{genimage_id}: #{e.message}"
      raise e
    end
  else
    Rails.logger.error "Failed to generate image for Genimage #{genimage_id}"
  end
end

private

    def build_prompt
      prompt = "generate an image of #{@menuitem.name}"
      prompt += ": #{@menuitem.description}" if @menuitem.description.present?

      if (restaurant = @menuitem.menusection&.menu&.restaurant)
        prompt += " The restaurant is a #{restaurant.imagecontext}." if restaurant.imagecontext.present?
      end

      if (menu = @menuitem.menusection&.menu)
        prompt += " The table setting is #{menu.imagecontext}." if menu.imagecontext.present?
      end

      prompt += " Showcasing the meal as the centerpiece. "
      prompt += "The focus is 75% on the tableware, capturing every detail of the food's presentation, "
      prompt += "while the background is blurred to emphasize the dish."

      prompt
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
