class UaLogger
  def initialize(app) = @app = app

  def call(env)
    status, headers, body = @app.call(env)
    Rails.logger.info("[UA] #{env['HTTP_USER_AGENT']} -> #{status} length=#{headers['Content-Length'] || 'chunked'}")
    [status, headers, body]
  end
end
