# frozen_string_literal: true

require 'test_helper'

class SeoGuidesTest < ActionDispatch::IntegrationTest
  setup do
    @published_guide = LocalGuide.create!(
      title: 'Best Italian Restaurants in Dublin',
      city: 'Dublin',
      country: 'Ireland',
      category: 'Italian',
      content: '<p>Discover the finest Italian dining in Dublin.</p>',
      status: :published,
      published_at: 1.day.ago,
      faq_data: [
        { 'question' => 'Where is the best pizza in Dublin?', 'answer' => 'Try Da Mimmo on North Strand.' },
      ],
    )
    @draft_guide = LocalGuide.create!(
      title: 'Draft Guide',
      city: 'Cork',
      country: 'Ireland',
      content: '<p>Not yet published.</p>',
      status: :draft,
    )
  end

  # ── Guides index ─────────────────────────────────────────────────────────

  test 'guides index returns 200' do
    get guides_path
    assert_response :success
  end

  test 'guides index shows only published guides' do
    get guides_path
    assert_match @published_guide.title, response.body
    assert_no_match(/Draft Guide/, response.body)
  end

  # ── Guides show ──────────────────────────────────────────────────────────

  test 'guide show returns 200 for published guide' do
    get guide_path(slug: @published_guide.slug)
    assert_response :success
  end

  test 'guide show includes Article JSON-LD' do
    get guide_path(slug: @published_guide.slug)
    json_ld = extract_json_ld(response.body)
    assert_equal 'Article', json_ld['@type']
    assert_equal @published_guide.title, json_ld['headline']
  end

  test 'guide show includes FAQPage when faq_data present' do
    get guide_path(slug: @published_guide.slug)
    json_ld = extract_json_ld(response.body)
    faq = json_ld['mainEntity']
    assert_equal 'FAQPage', faq['@type']
    assert_equal 1, faq['mainEntity'].length
    assert_equal 'Where is the best pizza in Dublin?', faq['mainEntity'].first['name']
  end

  test 'guide show has dynamic meta tags' do
    get guide_path(slug: @published_guide.slug)
    assert_select 'meta[property="og:title"]' do |tags|
      assert_match @published_guide.title, tags.first['content']
    end
    assert_select 'link[rel="canonical"]' do |tags|
      assert_match "guides/#{@published_guide.slug}", tags.first['href']
    end
  end

  test 'guide show returns 404 for draft guide' do
    get guide_path(slug: @draft_guide.slug)
    assert_response :not_found
  end

  test 'guide show returns 404 for non-existent slug' do
    get guide_path(slug: 'does-not-exist-xyz')
    assert_response :not_found
  end

  private

  def extract_json_ld(html)
    match = html.match(%r{<script type="application/ld\+json">\s*(.+?)\s*</script>}m)
    assert match, 'Expected JSON-LD script block in response'
    JSON.parse(match[1])
  end
end
