# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/vision', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
  path '/api/v1/vision/analyze' do
    post('Analyze Image with Google Vision API') do
      tags 'Vision AI'
      description 'Analyze uploaded images using Google Vision API for menu processing'
      consumes 'multipart/form-data'
      produces 'application/json'
      security [Bearer: []]
      
      parameter name: :image, in: :formData, type: :file, required: true,
                description: 'Image file to analyze (JPEG, PNG, GIF, BMP, WEBP, RAW, ICO, PDF, TIFF)'
      
      parameter name: :features, in: :formData, type: :string, required: false,
                description: 'Comma-separated list of features to detect',
                example: 'labels,text,web,objects,landmarks'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/VisionAnalysis'

        let(:image) { fixture_file_upload('test_menu.jpg', 'image/jpeg') }
        let(:features) { 'labels,text' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('labels')
          expect(data).to have_key('text')
        end
      end

      response(400, 'bad request - no image provided') do
        schema '$ref' => '#/components/schemas/Error'

        let(:image) { nil }
        run_test!
      end

      response(422, 'unprocessable entity - invalid image format') do
        schema '$ref' => '#/components/schemas/Error'

        let(:image) { fixture_file_upload('invalid.txt', 'text/plain') }
        run_test!
      end

      response(500, 'internal server error - vision API error') do
        schema '$ref' => '#/components/schemas/Error'

        let(:image) { fixture_file_upload('test_menu.jpg', 'image/jpeg') }
        
        before do
          allow_any_instance_of(GoogleVisionAnalyzable).to receive(:analyze_image)
            .and_raise(StandardError.new('Vision API error'))
        end

        run_test!
      end
    end
  end

  def generate_jwt_token(user)
    JwtService.generate_token_for_user(user)
  end
end
