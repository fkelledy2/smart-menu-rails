# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where OpenAPI JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve OpenAPI docs from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more OpenAPI documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete OpenAPI spec will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_doc tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_doc: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Smart Menu API V1',
        version: 'v1',
        description: 'Smart Menu Restaurant Management System API',
        contact: {
          name: 'Smart Menu Support',
          email: 'support@smartmenu.com'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      paths: {},
      servers: [
        {
          url: 'https://smartmenu.herokuapp.com',
          description: 'Production server'
        },
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          },
          ApiKey: {
            type: :apiKey,
            in: :header,
            name: 'X-API-Key'
          }
        },
        schemas: {
          Error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string },
                  message: { type: :string },
                  details: { type: :object }
                },
                required: [:code, :message]
              }
            },
            required: [:error]
          },
          Restaurant: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              address: { type: :string },
              phone: { type: :string },
              email: { type: :string },
              website: { type: :string },
              currency: { type: :string },
              timezone: { type: :string },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: [:id, :name]
          },
          Menu: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              restaurant_id: { type: :integer },
              active: { type: :boolean },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: [:id, :name, :restaurant_id]
          },
          MenuItem: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              price: { type: :number, format: :decimal },
              menu_section_id: { type: :integer },
              active: { type: :boolean },
              allergens: { type: :array, items: { type: :string } },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: [:id, :name, :price, :menu_section_id]
          },
          Order: {
            type: :object,
            properties: {
              id: { type: :integer },
              restaurant_id: { type: :integer },
              table_number: { type: :string },
              status: { type: :string, enum: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'] },
              total: { type: :number, format: :decimal },
              tax: { type: :number, format: :decimal },
              service_charge: { type: :number, format: :decimal },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: [:id, :restaurant_id, :status]
          },
          OrderItem: {
            type: :object,
            properties: {
              id: { type: :integer },
              order_id: { type: :integer },
              menu_item_id: { type: :integer },
              quantity: { type: :integer },
              unit_price: { type: :number, format: :decimal },
              total_price: { type: :number, format: :decimal },
              special_instructions: { type: :string },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: [:id, :order_id, :menu_item_id, :quantity, :unit_price]
          },
          AnalyticsEvent: {
            type: :object,
            properties: {
              event: { type: :string },
              properties: { type: :object },
              timestamp: { type: :string, format: :datetime }
            },
            required: [:event]
          },
          VisionAnalysis: {
            type: :object,
            properties: {
              labels: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    description: { type: :string },
                    score: { type: :number, format: :float }
                  }
                }
              },
              text: { type: :string },
              web: { type: :object },
              objects: { type: :array, items: { type: :object } }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output OpenAPI file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename, format and
  # the output folder. By default, the output folder is '<rails_root>/swagger'.
  config.openapi_format = :yaml
end
