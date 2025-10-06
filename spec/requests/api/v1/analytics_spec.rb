# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/analytics', type: :request do
  path '/api/v1/analytics/track' do
    post('Track Analytics Event') do
      tags 'Analytics'
      description 'Track user analytics events'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :event_data, in: :body, schema: {
        type: :object,
        properties: {
          event: { type: :string, description: 'Event name', example: 'menu_viewed' },
          properties: {
            type: :object,
            description: 'Event properties',
            example: {
              restaurant_id: 1,
              menu_id: 2,
              user_agent: 'Mozilla/5.0...'
            }
          }
        },
        required: [:event]
      }

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' }
               }

        let(:event_data) do
          {
            event: 'menu_viewed',
            properties: {
              restaurant_id: 1,
              menu_id: 2
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('success')
        end
      end

      response(400, 'bad request') do
        schema '$ref' => '#/components/schemas/Error'

        let(:event_data) { { invalid: 'data' } }
        run_test!
      end
    end
  end

  path '/api/v1/analytics/track_anonymous' do
    post('Track Anonymous Analytics Event') do
      tags 'Analytics'
      description 'Track analytics events for anonymous users'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :event_data, in: :body, schema: {
        type: :object,
        properties: {
          event: { type: :string, description: 'Event name', example: 'page_viewed' },
          properties: {
            type: :object,
            description: 'Event properties',
            example: {
              page: '/menu/123',
              referrer: 'https://google.com'
            }
          }
        },
        required: [:event]
      }

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' }
               }

        let(:event_data) do
          {
            event: 'page_viewed',
            properties: {
              page: '/menu/123'
            }
          }
        end

        run_test!
      end
    end
  end
end
