# frozen_string_literal: true

require 'test_helper'

class MenuSourceChangeDetectorTest < ActiveSupport::TestCase
  # Build a fake MenuSource with the interface the detector needs
  def build_menu_source(source_url: 'https://example.com/menu', last_fingerprint: nil, etag: nil, last_modified: nil, source_type: 'html')
    source = MenuSource.new(
      source_url: source_url,
      source_type: source_type,
      status: :active,
      last_fingerprint: last_fingerprint,
      etag: etag,
    )
    # Save without validation (avoids file attachment validation)
    source.save(validate: false)
    source
  end

  # Build an HTTP response double with given headers
  def stub_http_response(etag: nil, last_modified: nil)
    headers = {}
    headers['etag'] = etag if etag
    headers['last-modified'] = last_modified if last_modified

    resp = Object.new
    resp.define_singleton_method(:headers) { headers }
    resp
  end

  # A client that raises on head (simulates network failure)
  def failing_http_client
    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| raise 'connection refused' }
    client
  end

  # =========================================================================
  # blank URL guard
  # =========================================================================

  test 'returns false immediately when source_url is blank' do
    source = MenuSource.new(source_url: '', source_type: :html, status: :active)
    source.save(validate: false)

    detector = MenuSourceChangeDetector.new(menu_source: source)
    result = detector.call
    assert_equal false, result
  end

  # =========================================================================
  # no previous fingerprint — first check, cannot detect a change
  # =========================================================================

  test 'returns false on first check when no previous fingerprint exists' do
    source = build_menu_source(last_fingerprint: nil)
    resp = stub_http_response(etag: '"abc123"')

    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
    result = detector.call

    assert_equal false, result
  end

  test 'records last_checked_at on first check' do
    source = build_menu_source(last_fingerprint: nil)
    resp = stub_http_response(etag: '"v1"')

    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
    detector.call

    source.reload
    assert_not_nil source.last_checked_at
  end

  test 'stores fingerprint on first check when etag present' do
    source = build_menu_source(last_fingerprint: nil)
    resp = stub_http_response(etag: '"abc-etag"')

    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
    detector.call

    source.reload
    assert_not_nil source.last_fingerprint
  end

  # =========================================================================
  # change detected — etag differs
  # =========================================================================

  test 'returns true when etag changes between checks' do
    source = build_menu_source(last_fingerprint: 'old_fingerprint_sha', etag: '"old-etag"')
    resp = stub_http_response(etag: '"new-etag"')

    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    # Stub out the review/job creation side-effects
    MenuDiffJob.stub(:perform_later, nil) do
      detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
      result = detector.call
      assert_equal true, result
    end
  end

  test 'creates a menu_source_change_review when change detected' do
    source = build_menu_source(last_fingerprint: 'old_fp', etag: '"old-etag"')
    resp = stub_http_response(etag: '"new-etag"')

    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    review_count_before = source.menu_source_change_reviews.count

    MenuDiffJob.stub(:perform_later, nil) do
      detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
      detector.call
    end

    assert_equal review_count_before + 1, source.menu_source_change_reviews.reload.count
    review = source.menu_source_change_reviews.last
    assert_equal 'pending', review.status
    assert_equal 'old_fp', review.previous_fingerprint
  end

  test 'does not create a second review when a pending review already exists' do
    source = build_menu_source(last_fingerprint: 'old_fp', etag: '"old-etag"')
    # Pre-create a pending review
    source.menu_source_change_reviews.create!(
      status: :pending,
      detected_at: Time.current,
      previous_fingerprint: 'old_fp',
      new_fingerprint: 'some_new_fp',
    )

    resp = stub_http_response(etag: '"another-new-etag"')
    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    review_count_before = source.menu_source_change_reviews.count

    MenuDiffJob.stub(:perform_later, nil) do
      detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
      detector.call
    end

    assert_equal review_count_before, source.menu_source_change_reviews.reload.count
  end

  # =========================================================================
  # no change — same fingerprint
  # =========================================================================

  test 'returns false when etag is unchanged' do
    etag = '"unchanged-etag"'
    url = 'https://example.com/menu'

    require 'digest'
    existing_fp = Digest::SHA256.hexdigest([url, etag, ''].join('|'))
    source = build_menu_source(last_fingerprint: existing_fp, etag: etag)

    resp = stub_http_response(etag: etag)
    client = Object.new
    client.define_singleton_method(:head) { |*_args, **_kwargs| resp }

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: client)
    result = detector.call

    assert_equal false, result
  end

  # =========================================================================
  # network failure — safe_head returns nil
  # =========================================================================

  test 'returns false gracefully when HTTP head request fails' do
    source = build_menu_source(last_fingerprint: 'some_fp')

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: failing_http_client)
    result = detector.call

    # new_fingerprint will be nil (no etag/last-modified, not a pdf) so changed? is false
    assert_equal false, result
  end

  test 'still updates last_checked_at even when HTTP head fails' do
    source = build_menu_source(last_fingerprint: 'some_fp')
    source.update_column(:last_checked_at, 1.day.ago)

    detector = MenuSourceChangeDetector.new(menu_source: source, http_client: failing_http_client)
    detector.call

    source.reload
    assert source.last_checked_at > 1.minute.ago
  end
end
