# frozen_string_literal: true

require 'test_helper'

class LocalGuideGeneratorJobTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @restaurant.update_columns(
      preview_enabled: true,
      city: 'Dublin',
      country: 'Ireland',
    )
  end

  test 'job is enqueued on the default queue' do
    assert_equal 'default', LocalGuideGeneratorJob.new.queue_name
  end

  test 'generate_new_guide creates a draft LocalGuide' do
    fake_client = Object.new
    def fake_client.chat(parameters:)
      {
        'choices' => [
          {
            'message' => {
              'content' => '{"content":"<p>Dublin is vibrant for dining.</p>","faq":[{"question":"Best pasta?","answer":"Try the carbonara."}]}',
            },
          },
        ],
      }
    end

    OpenAI::Client.stub(:new, fake_client) do
      assert_difference('LocalGuide.count', 1) do
        LocalGuideGeneratorJob.perform_now(city: 'Dublin', category: nil)
      end
    end

    guide = LocalGuide.last
    assert_equal 'draft', guide.status
    assert_equal 'Dublin', guide.city
    assert_equal 'Ireland', guide.country
    assert guide.content.present?
    assert guide.faq_data.is_a?(Array)
  end

  test 'regenerate resets existing guide to draft' do
    guide = LocalGuide.create!(
      title: 'Old Guide',
      city: 'Dublin',
      country: 'Ireland',
      category: nil,
      content: '<p>Old content</p>',
      status: :published,
      published_at: 1.day.ago,
    )

    fake_client = Object.new
    def fake_client.chat(parameters:)
      {
        'choices' => [
          {
            'message' => {
              'content' => '{"content":"<p>Updated content about Dublin dining.</p>","faq":[]}',
            },
          },
        ],
      }
    end

    OpenAI::Client.stub(:new, fake_client) do
      LocalGuideGeneratorJob.perform_now(local_guide_id: guide.id)
    end

    guide.reload
    assert_equal 'draft', guide.status, 'Expected regenerated guide to reset to draft'
    assert_match(/Updated content/, guide.content)
  end

  test 'does not create guide when no restaurants match' do
    Restaurant.update_all(preview_enabled: false)

    assert_no_difference('LocalGuide.count') do
      LocalGuideGeneratorJob.perform_now(city: 'EmptyCity', category: 'Italian')
    end
  end
end
