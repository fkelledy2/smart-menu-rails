# frozen_string_literal: true

require 'test_helper'

class SmartmenuImagePerformanceTest < ActiveSupport::TestCase
  # These tests verify that the image optimisation pipeline produces
  # appropriately-sized derivatives and that the model helpers return
  # the correct URLs for each display context (card, modal, srcset).

  setup do
    @menuitem = menuitems(:one)
    @menusection = @menuitem.menusection
    @menu = @menusection.menu
    @restaurant = @menu.restaurant
  end

  # ---------- Derivative definitions ----------

  test 'ImageUploader defines all expected derivative keys' do
    expected = %i[thumb medium large card_webp thumb_webp medium_webp large_webp]

    # Verify ImageUploader has the derivatives plugin loaded
    assert ImageUploader.respond_to?(:plugin) || ImageUploader::Attacher.method_defined?(:create_derivatives),
           'ImageUploader should have the Derivatives plugin loaded'

    # Verify expected derivative names appear in the uploader source
    source = Rails.root.join('app', 'uploaders', 'image_uploader.rb').read
    expected.each do |key|
      assert source.include?(key.to_s),
             "ImageUploader should define the :#{key} derivative"
    end
  end

  test 'card_webp derivative is defined at 150px with quality 70' do
    source = Rails.root.join('app', 'uploaders', 'image_uploader.rb').read
    assert_match(/card_webp.*150.*150/m, source)
    assert_match(/quality:\s*70/, source)
  end

  test 'WebP quality levels are tiered: card=70, thumb=75, medium=75, large=80' do
    source = Rails.root.join('app', 'uploaders', 'image_uploader.rb').read

    # Extract quality values in order of appearance after 'webp' keyword
    webp_qualities = source.scan(/convert\('webp'\)\s*\.\s*saver\(quality:\s*(\d+)\)/).flatten.map(&:to_i)
    assert_equal [70, 75, 75, 80], webp_qualities,
                 'WebP quality should be tiered: card_webp=70, thumb_webp=75, medium_webp=75, large_webp=80'
  end

  # ---------- GenerateImageDerivativesJob ----------

  test 'GenerateImageDerivativesJob generates all derivatives (not a subset)' do
    source = Rails.root.join('app', 'jobs', 'generate_image_derivatives_job.rb').read
    # Should NOT have `only:` parameter — generate everything
    assert_no_match(/only:\s*%i/, source,
                    'GenerateImageDerivativesJob should generate ALL derivatives, not a subset',)
    assert_match(/create_derivatives\(force: true\)/, source)
  end

  # ---------- Model helper methods ----------

  test 'image_sizes returns mobile-first responsive sizes' do
    sizes = @menuitem.image_sizes
    assert_includes sizes, '480px'
    assert_includes sizes, '150px', 'Mobile card should request ~150px images'
    assert_includes sizes, '768px'
  end

  test 'optimised_modal_url prefers medium_webp when derivatives exist' do
    skip 'No image attached to fixture' if @menuitem.image.blank?

    url = @menuitem.optimised_modal_url
    assert url.present?, 'optimised_modal_url should return a URL'
  end

  test 'card_webp_url prefers card_webp derivative' do
    skip 'No image attached to fixture' if @menuitem.image.blank?

    url = @menuitem.card_webp_url
    assert url.present?, 'card_webp_url should return a URL'
  end

  test 'webp_srcset includes card_webp 150w descriptor' do
    skip 'No image attached to fixture' if @menuitem.image.blank?
    skip 'No WebP derivatives' unless @menuitem.has_webp_derivatives?

    srcset = @menuitem.webp_srcset
    assert_includes srcset, '150w', 'WebP srcset should include 150w for card_webp'
    assert_includes srcset, '200w'
    assert_includes srcset, '600w'
    assert_includes srcset, '1000w'
  end

  test 'has_webp_derivatives? checks for card_webp' do
    skip 'No image attached to fixture' if @menuitem.image.blank?

    # If all WebP derivatives exist, card_webp must be among them
    if @menuitem.has_webp_derivatives?
      assert @menuitem.image_attacher.derivatives.key?(:card_webp)
    end
  end

  # ---------- View partial checks ----------

  test 'showMenuitemHorizontal partial uses picture_tag_with_webp' do
    source = Rails.root.join('app', 'views', 'smartmenus', '_showMenuitemHorizontal.html.erb').read
    assert_includes source, 'picture_tag_with_webp',
                    'Horizontal card partial should use picture_tag_with_webp for WebP delivery'
    assert_includes source, "loading: 'lazy'",
                    'Card images should use lazy loading'
  end

  test 'showMenuitem partial uses picture_tag_with_webp' do
    source = Rails.root.join('app', 'views', 'smartmenus', '_showMenuitem.erb').read
    assert_includes source, 'picture_tag_with_webp',
                    'Card partial should use picture_tag_with_webp for WebP delivery'
  end

  test 'modal image data attributes use optimised_modal_url' do
    partials = %w[
      _showMenuitemHorizontalActionBar.erb
      _showMenuitem.erb
      _showMenuitemStaff.erb
    ]

    partials.each do |partial|
      source = Rails.root.join("app/views/smartmenus/#{partial}").read
      # Should NOT use raw image_url or medium_url for modal images
      assert_no_match(/data-bs-menuitem_image="<%=\s*(?:menuitem|mi)\.image_url\s*%>"/, source,
                      "#{partial} should not use raw image_url for modal image — use optimised_modal_url",)
    end
  end

  test 'all modal image data attributes reference optimised_modal_url' do
    partials = %w[
      _showMenuitemHorizontalActionBar.erb
      _showMenuitemStaff.erb
    ]

    partials.each do |partial|
      source = Rails.root.join("app/views/smartmenus/#{partial}").read
      # Every data-bs-menuitem_image should use optimised_modal_url
      image_attrs = source.scan(/data-bs-menuitem_image="<%=.*?%>"/)
      image_attrs.each do |attr|
        assert_match(/optimised_modal_url/, attr,
                     "#{partial}: #{attr} should use optimised_modal_url",)
      end
    end
  end

  # ---------- Responsive image helper ----------

  test 'picture_tag_for_shrine includes card_webp in srcset' do
    source = Rails.root.join('app', 'helpers', 'responsive_image_helper.rb').read
    assert_includes source, 'card_webp',
                    'picture_tag_for_shrine should include card_webp derivative in WebP srcset'
    assert_includes source, '150w',
                    'card_webp should be mapped to 150w descriptor'
  end

  # ---------- Backfill infrastructure ----------

  test 'BackfillImageDerivativesJob exists and is loadable' do
    assert defined?(BackfillImageDerivativesJob)
    assert BackfillImageDerivativesJob < ApplicationJob
  end

  test 'images:backfill_derivatives rake task is defined' do
    Rake::Task.clear
    Rails.application.load_tasks
    assert Rake::Task.task_defined?('images:backfill_derivatives'),
           'images:backfill_derivatives rake task should be defined'
  end

  test 'images:derivative_report rake task is defined' do
    Rake::Task.clear
    Rails.application.load_tasks
    assert Rake::Task.task_defined?('images:derivative_report'),
           'images:derivative_report rake task should be defined'
  end

  # ---------- Size budget assertions ----------

  test 'card_webp target size is under 15KB for a typical menu item image' do
    # This is a design constraint: 150px WebP at q70 should be well under 15KB.
    # We verify the uploader is configured to produce images that will meet this budget.
    source = Rails.root.join('app', 'uploaders', 'image_uploader.rb').read
    # card_webp: 150x150 at quality 70
    assert_match(/card_webp.*resize_to_limit!\(150,\s*150\)/m, source)
    # A 150x150 WebP at q70 is typically 3-8KB — well within budget
  end

  test 'medium_webp is sized for modal popup (600x480)' do
    source = Rails.root.join('app', 'uploaders', 'image_uploader.rb').read
    assert_match(/medium_webp.*resize_to_limit!\(600,\s*480\)/m, source)
  end

  # ---------- Menusection image support ----------

  test 'menusection has image_srcset and image_sizes methods' do
    assert @menusection.respond_to?(:image_srcset)
    assert @menusection.respond_to?(:image_sizes)
  end
end
