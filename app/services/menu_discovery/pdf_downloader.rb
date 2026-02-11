require 'tempfile'

module MenuDiscovery
  class PdfDownloader
    def initialize(http_client: HTTParty)
      @http_client = http_client
    end

    def download(url)
      resp = @http_client.get(url, headers: {
        'User-Agent' => 'SmartMenuBot/1.0 (+https://www.mellow.menu)',
        'Accept' => 'application/pdf,*/*',
      }, timeout: 30)

      return nil unless resp.respond_to?(:code)
      return nil unless resp.code.to_i >= 200 && resp.code.to_i < 300

      content_type = resp.headers['content-type'].to_s
      return nil unless content_type.include?('pdf') || url.to_s.downcase.end_with?('.pdf')

      tf = Tempfile.new(['menu', '.pdf'])
      tf.binmode
      tf.write(resp.body)
      tf.flush
      tf.rewind
      tf
    rescue StandardError
      nil
    end
  end
end
