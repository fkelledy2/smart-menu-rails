require 'digest'

class MenuDiffJob < ApplicationJob
  queue_as :default

  def perform(review_id:)
    review = MenuSourceChangeReview.find_by(id: review_id)
    return if review.nil?

    menu_source = review.menu_source
    return if menu_source.nil?

    url = menu_source.source_url.to_s
    if url.blank?
      review.update!(diff_status: :diff_failed, diff_content: 'No source URL')
      return
    end

    # Get the previous text from the stored PDF (if attached)
    previous_text = extract_text_from_attached(menu_source)

    # Download and extract text from the new version
    new_text = extract_text_from_url(url, menu_source.source_type.to_s)

    if new_text.blank?
      review.update!(diff_status: :diff_failed, diff_content: 'Could not extract text from new version')
      return
    end

    # Generate a simple line-by-line diff
    diff = generate_diff(previous_text.to_s, new_text)

    review.update!(
      diff_status: :diff_complete,
      diff_content: diff,
    )

    # Store the new PDF as the latest file for future diffs
    store_new_version!(menu_source, url) if menu_source.source_type.to_s == 'pdf'
  rescue StandardError => e
    Rails.logger.error("[MenuDiffJob] Failed for review_id=#{review_id}: #{e.class}: #{e.message}")
    review&.update(diff_status: :diff_failed, diff_content: "Error: #{e.message}")
  end

  private

  def extract_text_from_attached(menu_source)
    return nil unless menu_source.respond_to?(:latest_file) && menu_source.latest_file.attached?

    tempfile = Tempfile.new(['prev_menu', '.pdf'])
    tempfile.binmode
    tempfile.write(menu_source.latest_file.download)
    tempfile.rewind

    extract_pdf_text(tempfile.path)
  rescue StandardError => e
    Rails.logger.warn("[MenuDiffJob] Could not extract previous text: #{e.message}")
    nil
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  def extract_text_from_url(url, source_type)
    if source_type == 'pdf'
      tempfile = MenuDiscovery::PdfDownloader.new.download(url)
      return nil if tempfile.nil?

      extract_pdf_text(tempfile.path)
    else
      # HTML source — fetch and extract text
      resp = HTTParty.get(url, headers: {
        'User-Agent' => 'SmartMenuBot/1.0 (+https://www.mellow.menu)',
      }, timeout: 20)
      return nil unless resp.code == 200

      doc = Nokogiri::HTML(resp.body)
      doc.css('script, style, nav, footer, header').remove
      doc.text.gsub(/\s+/, ' ').strip
    end
  rescue StandardError => e
    Rails.logger.warn("[MenuDiffJob] extract_text_from_url failed: #{e.message}")
    nil
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  def extract_pdf_text(path)
    # Use the same approach as PdfMenuProcessor for text extraction
    reader = PDF::Reader.new(path)
    reader.pages.map(&:text).join("\n")
  rescue StandardError => e
    Rails.logger.warn("[MenuDiffJob] PDF text extraction failed: #{e.message}")
    nil
  end

  def generate_diff(old_text, new_text)
    old_lines = old_text.split("\n").map(&:strip).reject(&:blank?)
    new_lines = new_text.split("\n").map(&:strip).reject(&:blank?)

    old_set = old_lines.to_set
    new_set = new_lines.to_set

    added = new_lines.select { |l| !old_set.include?(l) }
    removed = old_lines.select { |l| !new_set.include?(l) }

    parts = []
    parts << "--- Previous version (#{old_lines.length} lines)" if old_text.present?
    parts << "+++ New version (#{new_lines.length} lines)"
    parts << ""

    if removed.any?
      parts << "REMOVED (#{removed.length} lines):"
      removed.first(100).each { |l| parts << "- #{l}" }
      parts << "... (#{removed.length - 100} more)" if removed.length > 100
      parts << ""
    end

    if added.any?
      parts << "ADDED (#{added.length} lines):"
      added.first(100).each { |l| parts << "+ #{l}" }
      parts << "... (#{added.length - 100} more)" if added.length > 100
      parts << ""
    end

    if added.empty? && removed.empty?
      parts << "(No text differences detected — change may be in formatting or metadata only)"
    end

    parts.join("\n")
  end

  def store_new_version!(menu_source, url)
    tempfile = MenuDiscovery::PdfDownloader.new.download(url)
    return if tempfile.nil?

    filename = File.basename(URI.parse(url).path.to_s.presence || 'menu.pdf')
    filename = 'menu.pdf' if filename.blank?

    menu_source.latest_file.attach(
      io: tempfile,
      filename: filename,
      content_type: 'application/pdf',
    )
  rescue StandardError => e
    Rails.logger.warn("[MenuDiffJob] store_new_version! failed: #{e.message}")
  ensure
    tempfile&.close
    tempfile&.unlink
  end
end
