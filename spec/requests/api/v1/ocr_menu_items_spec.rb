# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/ocr_menu_items', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:ocr_import) { create(:ocr_menu_import, restaurant: restaurant) }
  let(:ocr_section) { create(:ocr_menu_section, ocr_menu_import: ocr_import) }
  let(:ocr_item) { create(:ocr_menu_item, ocr_menu_section: ocr_section) }

  path '/api/v1/ocr_menu_items/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'OCR Menu Item ID'

    patch('Update OCR Menu Item') do
      tags 'OCR Processing'
      description 'Update OCR-processed menu item with corrections'
      consumes 'application/json'
      produces 'application/json'
      security [Bearer: []]
      
      parameter name: :item_data, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, description: 'Corrected item name', example: 'Margherita Pizza' },
          description: { type: :string, description: 'Item description', example: 'Classic pizza with tomato and mozzarella' },
          price: { type: :number, format: :decimal, description: 'Item price', example: 12.99 },
          category: { type: :string, description: 'Item category', example: 'Pizza' },
          allergens: { 
            type: :array, 
            items: { type: :string },
            description: 'List of allergens',
            example: ['gluten', 'dairy']
          },
          confidence_score: { type: :number, format: :float, description: 'OCR confidence score', example: 0.95 }
        }
      }

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 name: { type: :string },
                 description: { type: :string },
                 price: { type: :number, format: :decimal },
                 category: { type: :string },
                 allergens: { type: :array, items: { type: :string } },
                 confidence_score: { type: :number, format: :float },
                 status: { type: :string },
                 updated_at: { type: :string, format: :datetime }
               }

        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
        let(:id) { ocr_item.id }
        let(:item_data) do
          {
            name: 'Updated Pizza Name',
            description: 'Updated description',
            price: 15.99,
            category: 'Pizza'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['success']).to be true
          expect(data['data']['item']['name']).to eq('Updated Pizza Name')
          expect(data['data']['item']['price']).to eq(15.99)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'

        let(:Authorization) { nil }
        let(:id) { ocr_item.id }
        let(:item_data) { { name: 'Test' } }
        run_test!
      end

      response(403, 'forbidden - not owner') do
        schema '$ref' => '#/components/schemas/Error'

        let(:other_user) { create(:user) }
        let(:Authorization) { "Bearer #{generate_jwt_token(other_user)}" }
        let(:id) { ocr_item.id }
        let(:item_data) { { name: 'Test' } }
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'

        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
        let(:id) { 'nonexistent' }
        let(:item_data) { { name: 'Test' } }
        run_test!
      end

      response(422, 'unprocessable entity') do
        schema '$ref' => '#/components/schemas/Error'

        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }
        let(:id) { ocr_item.id }
        let(:item_data) { { price: 'invalid_price' } }
        run_test!
      end
    end
  end

  private

  def generate_jwt_token(user)
    JwtService.generate_token_for_user(user)
  end
end
