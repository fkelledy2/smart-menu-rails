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
      Rails.logger.debug { "GenerateImageJob prompt: #{prompt}" } if Rails.env.development? || Rails.env.test?
      response = generate_image(prompt, 1, default_image_size)
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

    def build_prompt
      section      = @menuitem.menusection
      menu         = section&.menu
      restaurant   = menu&.restaurant

      item_name    = @menuitem.name.to_s.strip
      item_desc    = @menuitem.description.to_s.strip
      sec_name     = section&.name.to_s.strip
      sec_desc     = section&.description.to_s.strip
      menu_ctx     = menu&.imagecontext.to_s.strip
      rest_name    = restaurant&.name.to_s.strip
      rest_desc    = restaurant&.try(:description).to_s.strip
      rest_img_ctx = restaurant&.imagecontext.to_s.strip

      # Ensure we have a persisted style profile for this restaurant to maximize consistency across items
      ensure_style_profile!(restaurant)

      style_profile = resolve_style_profile(restaurant)

      parts = []
      parts << "Generate a photorealistic image of #{item_name}#{item_desc.present? ? " — #{item_desc}" : ''}."
      if sec_name.present? || sec_desc.present?
        section_line = "This item appears in the #{sec_name} section"
        section_line += ": #{sec_desc}" if sec_desc.present?
        section_line += "."
        parts << section_line
      end

      brand_bits = [rest_desc, rest_img_ctx].reject(&:blank?).join('. ')
      parts << "Restaurant: #{rest_name}." if rest_name.present?
      parts << "Brand/cuisine context: #{brand_bits}." if brand_bits.present?
      parts << "Table setting context: #{menu_ctx}." if menu_ctx.present?

      # Visual direction for consistency across the same restaurant
      parts << "Style: #{style_profile}."
      parts << "Composition: hero dish centered, tight crop, shallow depth of field."
      parts << "Lighting: soft natural window light, gentle shadows."
      parts << "Angle/Lens: 45-degree angle, 50mm equivalent."
      parts << "Background/props: neutral linen, matte stoneware, rustic wooden table, minimal props."

      # Negative prompts to avoid common artifacts/drift
      parts << "Avoid: people, hands, logos, text, watermarks, duplicate dishes, messy background, cartoonish or illustrative style."

      join_parts(parts)
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

    # Ensure a restaurant-level image_style_profile exists; if missing, generate a short style guide
    # from available restaurant context via ask_question and persist it.
    def ensure_style_profile!(restaurant)
      return unless restaurant
      return unless restaurant.respond_to?(:image_style_profile)

      current = restaurant.image_style_profile.to_s.strip
      return if current.present?

      # Build a concise context for the LLM
      name      = restaurant.try(:name).to_s.strip
      desc      = restaurant.try(:description).to_s.strip
      img_ctx   = restaurant.try(:imagecontext).to_s.strip

      context_bits = []
      context_bits << "Name: #{name}." if name.present?
      context_bits << "Brand/Cuisine context: #{desc}." if desc.present?
      context_bits << "Image context hints: #{img_ctx}." if img_ctx.present?
      context_text = context_bits.join(' ')

      prompt = <<~PROMPT.strip
        You are a food photography art director. Based on the following restaurant brand context, produce a single-sentence food photography style guide to keep all menu item images visually consistent. Focus on visual style, lighting, angle/lens, props, and color mood. Avoid mentioning people or text. Be concise (max 30 words).
        #{context_text}
      PROMPT

      begin
        resp = ask_question(prompt)
        if resp&.success?
          content = resp.parsed_response.dig('choices', 0, 'message', 'content').to_s.strip
          if content.present?
            restaurant.update_column(:image_style_profile, content)
            Rails.logger.info("Generated image_style_profile for Restaurant ##{restaurant.id}")
          end
        else
          Rails.logger.warn("ask_question failed when generating style profile for Restaurant ##{restaurant.id}")
        end
      rescue => e
        Rails.logger.error("Error generating style profile for Restaurant ##{restaurant&.id}: #{e.message}")
      end
    end

    # Resolve a reusable, per-restaurant style profile to keep image generations consistent.
    # If your Restaurant model has an image_style_profile column, this method will use it when present.
    # Otherwise, we fall back to a sensible default profile influenced by restaurant context when available.
    def resolve_style_profile(restaurant)
      return default_style_profile unless restaurant

      # Prefer a stored, explicit style profile if the model provides it
      if restaurant.respond_to?(:image_style_profile)
        prof = restaurant.image_style_profile.to_s.strip
        return prof if prof.present?
      end

      hints = [restaurant.try(:imagecontext).to_s.strip, restaurant.try(:description).to_s.strip].reject(&:blank?).join('. ')
      base = default_style_profile
      hints.present? ? "#{base} Brand cues: #{hints}." : base
    end

    def default_style_profile
      "Realistic studio food photography; shallow depth of field; soft natural light; cohesive, muted color palette; matte stoneware plates; rustic wooden table; minimal, tasteful props"
    end

    def join_parts(parts)
      parts.compact.map { |s| s.to_s.strip }.reject(&:blank?).join(' ')
    end

    def default_image_size
      ENV['MENU_IMAGE_SIZE'].presence || '1024x1024'
    end

end

