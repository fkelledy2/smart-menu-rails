require 'digest'

class MenuSourceChangeDetector
  def initialize(menu_source:, http_client: HTTParty)
    @menu_source = menu_source
    @http_client = http_client
  end

  def call
    url = menu_source.source_url.to_s
    return false if url.blank?

    head = safe_head(url)

    new_etag = head&.headers&.[]('etag')&.to_s
    new_last_modified = parse_http_datetime(head&.headers&.[]('last-modified'))

    new_fingerprint = build_fingerprint(
      url: url,
      etag: new_etag,
      last_modified: new_last_modified,
    )

    changed = menu_source.last_fingerprint.present? && new_fingerprint.present? && menu_source.last_fingerprint != new_fingerprint

    if changed
      create_review!(
        previous_fingerprint: menu_source.last_fingerprint,
        new_fingerprint: new_fingerprint,
        previous_etag: menu_source.etag,
        new_etag: new_etag,
        previous_last_modified: menu_source.last_modified,
        new_last_modified: new_last_modified,
      )
    end

    menu_source.update!(
      last_checked_at: Time.current,
      last_fingerprint: new_fingerprint,
      etag: new_etag,
      last_modified: new_last_modified,
    )

    changed
  end

  private

  attr_reader :menu_source, :http_client

  def safe_head(url)
    http_client.head(url, headers: {
      'User-Agent' => 'SmartMenuBot/1.0 (+https://www.mellow.menu)',
      'Accept' => '*/*',
    }, timeout: 20,)
  rescue StandardError
    nil
  end

  def parse_http_datetime(value)
    return nil if value.blank?

    Time.httpdate(value.to_s)
  rescue StandardError
    nil
  end

  def build_fingerprint(url:, etag:, last_modified:)
    if etag.present? || last_modified.present?
      return Digest::SHA256.hexdigest([url, etag.to_s, last_modified&.utc&.iso8601].join('|'))
    end

    return nil unless menu_source.source_type.to_s == 'pdf'

    tempfile = MenuDiscovery::PdfDownloader.new.download(url)
    return nil if tempfile.nil?

    Digest::SHA256.file(tempfile.path).hexdigest
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  def create_review!(previous_fingerprint:, new_fingerprint:, previous_etag:, new_etag:, previous_last_modified:, new_last_modified:)
    return if menu_source.menu_source_change_reviews.pending.exists?

    review = menu_source.menu_source_change_reviews.create!(
      status: :pending,
      detected_at: Time.current,
      previous_fingerprint: previous_fingerprint,
      new_fingerprint: new_fingerprint,
      previous_etag: previous_etag,
      new_etag: new_etag,
      previous_last_modified: previous_last_modified,
      new_last_modified: new_last_modified,
    )

    MenuDiffJob.perform_later(review_id: review.id)
  end
end
