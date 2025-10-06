Rswag::Ui.configure do |c|
  # List the OpenAPI endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path (absolute or relative to domain) to the corresponding
  # endpoint and the second is a title that will be displayed in the document selector
  # NOTE: If you're using rswag-specs to generate OpenAPI docs, you'll need to ensure
  # that it's configured to generate files in the same folder
  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'Smart Menu API V1 Docs'

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
