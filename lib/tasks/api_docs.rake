# frozen_string_literal: true

namespace :api_docs do
  desc 'Generate OpenAPI/Swagger documentation'
  task generate: :environment do
    puts '🔄 Generating API documentation...'
    
    # Create swagger directory
    swagger_dir = Rails.root.join('swagger/v1')
    FileUtils.mkdir_p(swagger_dir)
    
    # Generate basic OpenAPI specification
    openapi_spec = {
      openapi: '3.0.1',
      info: {
        title: 'Smart Menu API V1',
        version: 'v1',
        description: 'Smart Menu Restaurant Management System API',
        contact: {
          name: 'Smart Menu Support',
          email: 'support@smartmenu.com'
        }
      },
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
      paths: generate_api_paths,
      components: {
        securitySchemes: {
          Bearer: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          }
        },
        schemas: generate_api_schemas
      }
    }
    
    # Write to file
    File.write(swagger_dir.join('swagger.yaml'), openapi_spec.to_yaml)
    
    puts '✅ API documentation generated successfully!'
    puts "📁 Generated: #{swagger_dir.join('swagger.yaml')}"
    puts '📖 View documentation at: http://localhost:3000/api-docs'
  end

  desc 'Validate API documentation'
  task validate: :environment do
    puts '🔄 Validating API documentation...'
    
    swagger_file = Rails.root.join('swagger/v1/swagger.yaml')
    
    if File.exist?(swagger_file)
      begin
        content = YAML.load_file(swagger_file)
        
        # Basic validation
        required_fields = %w[openapi info paths]
        missing_fields = required_fields.reject { |field| content.key?(field) }
        
        if missing_fields.empty?
          puts '✅ API documentation is valid!'
          puts "📊 Found #{content['paths']&.keys&.size || 0} documented endpoints"
        else
          puts "❌ API documentation is missing required fields: #{missing_fields.join(', ')}"
          exit 1
        end
      rescue => e
        puts "❌ Error validating API documentation: #{e.message}"
        exit 1
      end
    else
      puts '❌ API documentation file not found. Run rake api_docs:generate first.'
      exit 1
    end
  end

  desc 'Export API documentation to different formats'
  task :export, [:format] => :environment do |t, args|
    format = args[:format] || 'json'
    
    puts "🔄 Exporting API documentation to #{format.upcase}..."
    
    swagger_file = Rails.root.join('swagger/v1/swagger.yaml')
    
    unless File.exist?(swagger_file)
      puts '❌ API documentation file not found. Run rake api_docs:generate first.'
      exit 1
    end
    
    content = YAML.load_file(swagger_file)
    output_dir = Rails.root.join('public/api-docs')
    FileUtils.mkdir_p(output_dir)
    
    case format.downcase
    when 'json'
      output_file = output_dir.join('swagger.json')
      File.write(output_file, JSON.pretty_generate(content))
      puts "✅ Exported to #{output_file}"
    when 'yaml', 'yml'
      output_file = output_dir.join('swagger.yaml')
      File.write(output_file, content.to_yaml)
      puts "✅ Exported to #{output_file}"
    when 'html'
      generate_html_docs(content, output_dir)
      puts "✅ Exported HTML documentation to #{output_dir}/index.html"
    else
      puts "❌ Unsupported format: #{format}. Supported formats: json, yaml, html"
      exit 1
    end
  end

  desc 'Generate API client libraries'
  task generate_clients: :environment do
    puts '🔄 Generating API client libraries...'
    
    swagger_file = Rails.root.join('swagger/v1/swagger.yaml')
    
    unless File.exist?(swagger_file)
      puts '❌ API documentation file not found. Run rake api_docs:generate first.'
      exit 1
    end
    
    clients_dir = Rails.root.join('public/api-clients')
    FileUtils.mkdir_p(clients_dir)
    
    # Generate JavaScript/TypeScript client
    generate_js_client(swagger_file, clients_dir)
    
    # Generate Python client
    generate_python_client(swagger_file, clients_dir)
    
    puts '✅ API client libraries generated!'
    puts "📁 Check #{clients_dir} for generated clients"
  end

  desc 'Start documentation server'
  task serve: :environment do
    puts '🚀 Starting API documentation server...'
    puts '📖 Documentation available at: http://localhost:3000/api-docs'
    puts '🛑 Press Ctrl+C to stop'
    
    # This would typically start a separate server, but since we're using Rails
    # we'll just remind the user to start the Rails server
    puts '💡 Make sure your Rails server is running: rails server'
  end

  private

  def generate_api_paths
    {
      # Restaurant Management
      '/api/v1/restaurants' => {
        get: {
          tags: ['Restaurants'],
          summary: 'List Restaurants',
          description: 'Get a list of all restaurants',
          security: [{ Bearer: [] }],
          responses: {
            '200' => {
              description: 'List of restaurants',
              content: {
                'application/json' => {
                  schema: {
                    type: 'array',
                    items: { '$ref' => '#/components/schemas/Restaurant' }
                  }
                }
              }
            }
          }
        },
        post: {
          tags: ['Restaurants'],
          summary: 'Create Restaurant',
          description: 'Create a new restaurant',
          security: [{ Bearer: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/RestaurantInput' }
              }
            }
          },
          responses: {
            '201' => {
              description: 'Restaurant created',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Restaurant' }
                }
              }
            }
          }
        }
      },
      '/api/v1/restaurants/{id}' => {
        get: {
          tags: ['Restaurants'],
          summary: 'Get Restaurant',
          description: 'Get a specific restaurant by ID',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '200' => {
              description: 'Restaurant details',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Restaurant' }
                }
              }
            }
          }
        },
        put: {
          tags: ['Restaurants'],
          summary: 'Update Restaurant',
          description: 'Update a restaurant',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/RestaurantInput' }
              }
            }
          },
          responses: {
            '200' => {
              description: 'Restaurant updated',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Restaurant' }
                }
              }
            }
          }
        },
        delete: {
          tags: ['Restaurants'],
          summary: 'Delete Restaurant',
          description: 'Delete a restaurant',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '204' => { description: 'Restaurant deleted' }
          }
        }
      },
      
      # Menu Management
      '/api/v1/restaurants/{restaurant_id}/menus' => {
        get: {
          tags: ['Menus'],
          summary: 'List Restaurant Menus',
          description: 'Get all menus for a restaurant',
          parameters: [
            {
              name: 'restaurant_id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '200' => {
              description: 'List of menus',
              content: {
                'application/json' => {
                  schema: {
                    type: 'array',
                    items: { '$ref' => '#/components/schemas/Menu' }
                  }
                }
              }
            }
          }
        },
        post: {
          tags: ['Menus'],
          summary: 'Create Menu',
          description: 'Create a new menu for a restaurant',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'restaurant_id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/MenuInput' }
              }
            }
          },
          responses: {
            '201' => {
              description: 'Menu created',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Menu' }
                }
              }
            }
          }
        }
      },
      '/api/v1/menus/{id}' => {
        get: {
          tags: ['Menus'],
          summary: 'Get Menu',
          description: 'Get a specific menu with items',
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '200' => {
              description: 'Menu with items',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/MenuWithItems' }
                }
              }
            }
          }
        }
      },
      
      # Menu Items
      '/api/v1/menus/{menu_id}/items' => {
        get: {
          tags: ['Menu Items'],
          summary: 'List Menu Items',
          description: 'Get all items for a menu',
          parameters: [
            {
              name: 'menu_id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '200' => {
              description: 'List of menu items',
              content: {
                'application/json' => {
                  schema: {
                    type: 'array',
                    items: { '$ref' => '#/components/schemas/MenuItem' }
                  }
                }
              }
            }
          }
        }
      },
      
      # Orders
      '/api/v1/restaurants/{restaurant_id}/orders' => {
        get: {
          tags: ['Orders'],
          summary: 'List Restaurant Orders',
          description: 'Get all orders for a restaurant',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'restaurant_id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            },
            {
              name: 'status',
              in: 'query',
              required: false,
              schema: { 
                type: 'string',
                enum: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled']
              }
            }
          ],
          responses: {
            '200' => {
              description: 'List of orders',
              content: {
                'application/json' => {
                  schema: {
                    type: 'array',
                    items: { '$ref' => '#/components/schemas/Order' }
                  }
                }
              }
            }
          }
        },
        post: {
          tags: ['Orders'],
          summary: 'Create Order',
          description: 'Create a new order',
          parameters: [
            {
              name: 'restaurant_id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: { '$ref' => '#/components/schemas/OrderInput' }
              }
            }
          },
          responses: {
            '201' => {
              description: 'Order created',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Order' }
                }
              }
            }
          }
        }
      },
      '/api/v1/orders/{id}' => {
        get: {
          tags: ['Orders'],
          summary: 'Get Order',
          description: 'Get a specific order with items',
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          responses: {
            '200' => {
              description: 'Order with items',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/OrderWithItems' }
                }
              }
            }
          }
        },
        patch: {
          tags: ['Orders'],
          summary: 'Update Order Status',
          description: 'Update order status',
          security: [{ Bearer: [] }],
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    status: { 
                      type: 'string',
                      enum: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled']
                    }
                  },
                  required: ['status']
                }
              }
            }
          },
          responses: {
            '200' => {
              description: 'Order updated',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/Order' }
                }
              }
            }
          }
        }
      },
      
      # Analytics
      '/api/v1/analytics/track' => {
        post: {
          tags: ['Analytics'],
          summary: 'Track Analytics Event',
          description: 'Track user analytics events',
          requestBody: {
            required: true,
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    event: { type: 'string', example: 'menu_viewed' },
                    properties: { type: 'object', example: { restaurant_id: 1 } }
                  },
                  required: ['event']
                }
              }
            }
          },
          responses: {
            '200' => {
              description: 'Success',
              content: {
                'application/json' => {
                  schema: {
                    type: 'object',
                    properties: {
                      status: { type: 'string', example: 'success' }
                    }
                  }
                }
              }
            }
          }
        }
      },
      
      # Vision AI
      '/api/v1/vision/analyze' => {
        post: {
          tags: ['Vision AI'],
          summary: 'Analyze Image',
          description: 'Analyze uploaded images using Google Vision API',
          requestBody: {
            required: true,
            content: {
              'multipart/form-data' => {
                schema: {
                  type: 'object',
                  properties: {
                    image: { type: 'string', format: 'binary' },
                    features: { type: 'string', example: 'labels,text' }
                  },
                  required: ['image']
                }
              }
            }
          },
          responses: {
            '200' => {
              description: 'Analysis results',
              content: {
                'application/json' => {
                  schema: { '$ref' => '#/components/schemas/VisionAnalysis' }
                }
              }
            }
          }
        }
      }
    }
  end

  def generate_api_schemas
    {
      Restaurant: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Bella Vista Restaurant' },
          description: { type: 'string', example: 'Authentic Italian cuisine' },
          address: { type: 'string', example: '123 Main St, City' },
          phone: { type: 'string', example: '+1-555-0123' },
          email: { type: 'string', format: 'email', example: 'info@bellavista.com' },
          website: { type: 'string', format: 'uri', example: 'https://bellavista.com' },
          currency: { type: 'string', example: 'USD' },
          timezone: { type: 'string', example: 'America/New_York' },
          active: { type: 'boolean', example: true },
          created_at: { type: 'string', format: 'date-time' },
          updated_at: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'name']
      },
      RestaurantInput: {
        type: 'object',
        properties: {
          name: { type: 'string', example: 'Bella Vista Restaurant' },
          description: { type: 'string', example: 'Authentic Italian cuisine' },
          address: { type: 'string', example: '123 Main St, City' },
          phone: { type: 'string', example: '+1-555-0123' },
          email: { type: 'string', format: 'email', example: 'info@bellavista.com' },
          website: { type: 'string', format: 'uri', example: 'https://bellavista.com' },
          currency: { type: 'string', example: 'USD' },
          timezone: { type: 'string', example: 'America/New_York' }
        },
        required: ['name']
      },
      Menu: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Dinner Menu' },
          description: { type: 'string', example: 'Our evening dinner selection' },
          restaurant_id: { type: 'integer', example: 1 },
          active: { type: 'boolean', example: true },
          created_at: { type: 'string', format: 'date-time' },
          updated_at: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'name', 'restaurant_id']
      },
      MenuInput: {
        type: 'object',
        properties: {
          name: { type: 'string', example: 'Dinner Menu' },
          description: { type: 'string', example: 'Our evening dinner selection' },
          active: { type: 'boolean', example: true }
        },
        required: ['name']
      },
      MenuWithItems: {
        allOf: [
          { '$ref' => '#/components/schemas/Menu' },
          {
            type: 'object',
            properties: {
              sections: {
                type: 'array',
                items: { '$ref' => '#/components/schemas/MenuSection' }
              }
            }
          }
        ]
      },
      MenuSection: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Appetizers' },
          description: { type: 'string', example: 'Start your meal right' },
          position: { type: 'integer', example: 1 },
          items: {
            type: 'array',
            items: { '$ref' => '#/components/schemas/MenuItem' }
          }
        }
      },
      MenuItem: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Margherita Pizza' },
          description: { type: 'string', example: 'Fresh tomato, mozzarella, basil' },
          price: { type: 'number', format: 'decimal', example: 12.99 },
          menu_section_id: { type: 'integer', example: 1 },
          active: { type: 'boolean', example: true },
          allergens: { 
            type: 'array', 
            items: { type: 'string' },
            example: ['gluten', 'dairy']
          },
          dietary_info: {
            type: 'object',
            properties: {
              vegetarian: { type: 'boolean' },
              vegan: { type: 'boolean' },
              gluten_free: { type: 'boolean' }
            }
          },
          created_at: { type: 'string', format: 'date-time' },
          updated_at: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'name', 'price', 'menu_section_id']
      },
      Order: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          restaurant_id: { type: 'integer', example: 1 },
          table_number: { type: 'string', example: 'T-12' },
          status: { 
            type: 'string', 
            enum: ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'],
            example: 'pending'
          },
          customer_name: { type: 'string', example: 'John Doe' },
          customer_phone: { type: 'string', example: '+1-555-0123' },
          subtotal: { type: 'number', format: 'decimal', example: 25.99 },
          tax: { type: 'number', format: 'decimal', example: 2.60 },
          service_charge: { type: 'number', format: 'decimal', example: 3.90 },
          total: { type: 'number', format: 'decimal', example: 32.49 },
          notes: { type: 'string', example: 'Extra napkins please' },
          created_at: { type: 'string', format: 'date-time' },
          updated_at: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'restaurant_id', 'status']
      },
      OrderInput: {
        type: 'object',
        properties: {
          table_number: { type: 'string', example: 'T-12' },
          customer_name: { type: 'string', example: 'John Doe' },
          customer_phone: { type: 'string', example: '+1-555-0123' },
          notes: { type: 'string', example: 'Extra napkins please' },
          items: {
            type: 'array',
            items: { '$ref' => '#/components/schemas/OrderItemInput' }
          }
        },
        required: ['items']
      },
      OrderWithItems: {
        allOf: [
          { '$ref' => '#/components/schemas/Order' },
          {
            type: 'object',
            properties: {
              items: {
                type: 'array',
                items: { '$ref' => '#/components/schemas/OrderItem' }
              }
            }
          }
        ]
      },
      OrderItem: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          order_id: { type: 'integer', example: 1 },
          menu_item_id: { type: 'integer', example: 1 },
          menu_item_name: { type: 'string', example: 'Margherita Pizza' },
          quantity: { type: 'integer', example: 2 },
          unit_price: { type: 'number', format: 'decimal', example: 12.99 },
          total_price: { type: 'number', format: 'decimal', example: 25.98 },
          special_instructions: { type: 'string', example: 'Extra cheese' },
          created_at: { type: 'string', format: 'date-time' },
          updated_at: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'order_id', 'menu_item_id', 'quantity', 'unit_price']
      },
      OrderItemInput: {
        type: 'object',
        properties: {
          menu_item_id: { type: 'integer', example: 1 },
          quantity: { type: 'integer', example: 2 },
          special_instructions: { type: 'string', example: 'Extra cheese' }
        },
        required: ['menu_item_id', 'quantity']
      },
      VisionAnalysis: {
        type: 'object',
        properties: {
          labels: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                description: { type: 'string' },
                score: { type: 'number', format: 'float' }
              }
            }
          },
          text: { type: 'string' },
          web: { type: 'object' },
          objects: { type: 'array', items: { type: 'object' } }
        }
      },
      AnalyticsEvent: {
        type: 'object',
        properties: {
          event: { type: 'string', example: 'menu_viewed' },
          properties: { 
            type: 'object',
            example: {
              restaurant_id: 1,
              menu_id: 2,
              user_agent: 'Mozilla/5.0...'
            }
          },
          timestamp: { type: 'string', format: 'date-time' }
        },
        required: ['event']
      },
      Error: {
        type: 'object',
        properties: {
          error: {
            type: 'object',
            properties: {
              code: { type: 'string', example: 'VALIDATION_ERROR' },
              message: { type: 'string', example: 'The request is invalid' },
              details: { 
                type: 'object',
                example: { field: 'name', issue: 'is required' }
              }
            },
            required: ['code', 'message']
          }
        },
        required: ['error']
      }
    }
  end

  def generate_html_docs(content, output_dir)
    html_template = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <title>Smart Menu API Documentation</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui.css" />
        <style>
          html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
          *, *:before, *:after { box-sizing: inherit; }
          body { margin:0; background: #fafafa; }
        </style>
      </head>
      <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui-bundle.js"></script>
        <script src="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui-standalone-preset.js"></script>
        <script>
          window.onload = function() {
            const ui = SwaggerUIBundle({
              spec: #{content.to_json},
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
              ],
              layout: "StandaloneLayout"
            });
          };
        </script>
      </body>
      </html>
    HTML
    
    File.write(output_dir.join('index.html'), html_template)
  end

  def generate_js_client(swagger_file, output_dir)
    js_client = <<~JS
      // Smart Menu API JavaScript Client
      // Generated from OpenAPI specification
      
      class SmartMenuAPI {
        constructor(baseURL = 'http://localhost:3000', apiKey = null) {
          this.baseURL = baseURL;
          this.apiKey = apiKey;
        }
        
        async request(method, path, data = null) {
          const url = `${this.baseURL}${path}`;
          const headers = {
            'Content-Type': 'application/json',
          };
          
          if (this.apiKey) {
            headers['X-API-Key'] = this.apiKey;
          }
          
          const options = {
            method,
            headers,
          };
          
          if (data) {
            options.body = JSON.stringify(data);
          }
          
          const response = await fetch(url, options);
          
          if (!response.ok) {
            throw new Error(`API request failed: ${response.status} ${response.statusText}`);
          }
          
          return response.json();
        }
        
        // Analytics endpoints
        async trackEvent(event, properties = {}) {
          return this.request('POST', '/api/v1/analytics/track', { event, properties });
        }
        
        async trackAnonymousEvent(event, properties = {}) {
          return this.request('POST', '/api/v1/analytics/track_anonymous', { event, properties });
        }
        
        // Vision API endpoints
        async analyzeImage(imageFile, features = 'labels,text') {
          const formData = new FormData();
          formData.append('image', imageFile);
          formData.append('features', features);
          
          const response = await fetch(`${this.baseURL}/api/v1/vision/analyze`, {
            method: 'POST',
            body: formData,
          });
          
          if (!response.ok) {
            throw new Error(`Vision API request failed: ${response.status} ${response.statusText}`);
          }
          
          return response.json();
        }
      }
      
      // Export for Node.js and browser
      if (typeof module !== 'undefined' && module.exports) {
        module.exports = SmartMenuAPI;
      } else {
        window.SmartMenuAPI = SmartMenuAPI;
      }
    JS
    
    File.write(output_dir.join('smart-menu-api.js'), js_client)
  end

  def generate_python_client(swagger_file, output_dir)
    python_client = <<~PYTHON
      """
      Smart Menu API Python Client
      Generated from OpenAPI specification
      """
      
      import requests
      import json
      from typing import Dict, Any, Optional
      
      class SmartMenuAPI:
          def __init__(self, base_url: str = "http://localhost:3000", api_key: Optional[str] = None):
              self.base_url = base_url
              self.api_key = api_key
              self.session = requests.Session()
              
              if api_key:
                  self.session.headers.update({"X-API-Key": api_key})
          
          def _request(self, method: str, path: str, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
              url = f"{self.base_url}{path}"
              
              if method.upper() == "GET":
                  response = self.session.get(url, params=data)
              elif method.upper() == "POST":
                  response = self.session.post(url, json=data)
              elif method.upper() == "PUT":
                  response = self.session.put(url, json=data)
              elif method.upper() == "PATCH":
                  response = self.session.patch(url, json=data)
              elif method.upper() == "DELETE":
                  response = self.session.delete(url)
              else:
                  raise ValueError(f"Unsupported HTTP method: {method}")
              
              response.raise_for_status()
              return response.json()
          
          def track_event(self, event: str, properties: Dict[str, Any] = None) -> Dict[str, Any]:
              """Track an analytics event"""
              data = {"event": event}
              if properties:
                  data["properties"] = properties
              return self._request("POST", "/api/v1/analytics/track", data)
          
          def track_anonymous_event(self, event: str, properties: Dict[str, Any] = None) -> Dict[str, Any]:
              """Track an anonymous analytics event"""
              data = {"event": event}
              if properties:
                  data["properties"] = properties
              return self._request("POST", "/api/v1/analytics/track_anonymous", data)
          
          def analyze_image(self, image_path: str, features: str = "labels,text") -> Dict[str, Any]:
              """Analyze an image using Google Vision API"""
              url = f"{self.base_url}/api/v1/vision/analyze"
              
              with open(image_path, 'rb') as image_file:
                  files = {'image': image_file}
                  data = {'features': features}
                  response = requests.post(url, files=files, data=data)
              
              response.raise_for_status()
              return response.json()
      
      # Example usage
      if __name__ == "__main__":
          api = SmartMenuAPI()
          
          # Track an event
          result = api.track_anonymous_event("page_viewed", {"page": "/menu/123"})
          print("Event tracked:", result)
    PYTHON
    
    File.write(output_dir.join('smart_menu_api.py'), python_client)
  end
end
