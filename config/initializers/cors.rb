Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      'https://mellow.menu',
      'https://www.mellow.menu',
      /\Ahttps:\/\/[\w-]+\.mellow\.menu\z/,
      *(Rails.env.local? ? ['http://localhost:3000', /\Ahttp:\/\/localhost:\d+\z/] : []),
    )
    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true,
      max_age: 86_400
  end
end