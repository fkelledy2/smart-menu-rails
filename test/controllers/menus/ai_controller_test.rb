# frozen_string_literal: true

require 'test_helper'

class Menus::AiControllerTest < ActionDispatch::IntegrationTest
  # Menus::AiController tests.
  # Focuses on: authentication, authorization, enqueuing AI jobs, progress polling.
  #
  # Stubs used:
  #   - MenuItemImageBatchJob.perform_async  — avoids Sidekiq
  #   - RegenerateMenuWebpJob.perform_async  — avoids Sidekiq
  #   - AiMenuPolisherJob.perform_async      — avoids Sidekiq
  #   - BeverageIntelligence::PairingEngine  — avoids OpenAI/DB-heavy pairing
  #   - Sidekiq.redis                        — avoids Redis dependency for progress keys

  def setup
    @owner      = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @menu       = menus(:one)

    # Fixtures bypass after_commit; ensure restaurant_menus join record exists.
    RestaurantMenu.find_or_create_by!(restaurant_id: @restaurant.id, menu_id: @menu.id) do |rm|
      rm.sequence = 1
      rm.status = :active
      rm.availability_state = :available
    end

    @fake_jid = 'abc123def456'
  end

  # Stub Sidekiq.redis to be a no-op (avoid Redis in tests)
  def stub_sidekiq_redis(&block)
    Sidekiq.stub(:redis, ->(*, &_blk) {}) do
      block.call
    end
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/menus/:id/regenerate_images
  # ---------------------------------------------------------------------------

  test 'POST regenerate_images redirects unauthenticated' do
    post regenerate_images_restaurant_menu_path(@restaurant, @menu)
    assert_redirected_to new_user_session_path
  end

  test 'POST regenerate_images as JSON enqueues image batch job when generate_ai=true' do
    sign_in @owner

    MenuItemImageBatchJob.stub(:perform_async, @fake_jid) do
      stub_sidekiq_redis do
        post regenerate_images_restaurant_menu_path(@restaurant, @menu),
             params: { generate_ai: 'true' },
             as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @fake_jid, body['job_id']
    assert_equal 'queued', body['status']
  end

  test 'POST regenerate_images enqueues webp job when generate_ai is not true' do
    sign_in @owner

    webp_called = false
    RegenerateMenuWebpJob.stub(:perform_async, ->(_mid) { webp_called = true; @fake_jid }) do
      post regenerate_images_restaurant_menu_path(@restaurant, @menu),
           params: { generate_ai: 'false' }
    end

    assert webp_called, 'RegenerateMenuWebpJob should have been enqueued'
    assert_redirected_to edit_restaurant_menu_path(@restaurant, @menu)
  end

  test 'POST regenerate_images denied for non-owner' do
    sign_in @other_user

    post regenerate_images_restaurant_menu_path(@restaurant, @menu),
         params: { generate_ai: 'true' },
         as: :json

    assert_response :forbidden
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/menus/:id/image_generation_progress
  # ---------------------------------------------------------------------------

  test 'GET image_generation_progress returns progress JSON for owner' do
    sign_in @owner

    progress_payload = {
      status: 'in_progress',
      current: 3,
      total: 10,
      job_id: @fake_jid,
      menu_id: @menu.id,
    }.to_json

    # Stub Sidekiq.redis to yield a fake connection that returns our payload
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get) { |_key| progress_payload }
    Sidekiq.stub(:redis, ->(*, &blk) { blk.call(fake_redis) }) do
      get image_generation_progress_restaurant_menu_path(@restaurant, @menu),
          params: { job_id: @fake_jid },
          as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert_equal 'in_progress', body['status']
    assert_equal @fake_jid, body['job_id']
  end

  test 'GET image_generation_progress returns empty payload on Redis error' do
    sign_in @owner

    Sidekiq.stub(:redis, ->(*_args) { raise StandardError, 'Redis unavailable' }) do
      get image_generation_progress_restaurant_menu_path(@restaurant, @menu),
          params: { job_id: @fake_jid },
          as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @fake_jid, body['job_id']
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/menus/:id/polish
  # ---------------------------------------------------------------------------

  test 'POST polish as JSON enqueues AiMenuPolisherJob for owner' do
    sign_in @owner

    AiMenuPolisherJob.stub(:perform_async, @fake_jid) do
      stub_sidekiq_redis do
        post polish_restaurant_menu_path(@restaurant, @menu), as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @fake_jid, body['job_id']
    assert_equal 'queued', body['status']
  end

  test 'POST polish denied for non-owner' do
    sign_in @other_user

    post polish_restaurant_menu_path(@restaurant, @menu), as: :json

    assert_response :forbidden
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/menus/:id/polish_progress
  # ---------------------------------------------------------------------------

  test 'GET polish_progress returns progress JSON for owner' do
    sign_in @owner

    progress_payload = { status: 'queued', current: 0, total: 5, job_id: @fake_jid }.to_json
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get) { |_key| progress_payload }

    Sidekiq.stub(:redis, ->(*, &blk) { blk.call(fake_redis) }) do
      get polish_progress_restaurant_menu_path(@restaurant, @menu),
          params: { job_id: @fake_jid },
          as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @fake_jid, body['job_id']
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/menus/:id/generate_pairings
  # ---------------------------------------------------------------------------

  test 'POST generate_pairings as JSON returns pairing count for owner' do
    sign_in @owner

    fake_engine = Object.new
    fake_engine.define_singleton_method(:generate_for_menu) { |_menu| 5 }

    BeverageIntelligence::PairingEngine.stub(:new, fake_engine) do
      PairingRecommendation.stub(:joins, PairingRecommendation.none) do
        post generate_pairings_restaurant_menu_path(@restaurant, @menu), as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal 5, body['pairings_count']
  end

  test 'POST generate_pairings returns 500 on engine error' do
    sign_in @owner

    BeverageIntelligence::PairingEngine.stub(:new, -> { raise StandardError, 'AI error' }) do
      post generate_pairings_restaurant_menu_path(@restaurant, @menu), as: :json
    end

    assert_response :internal_server_error
  end

  test 'POST generate_pairings denied for non-owner' do
    sign_in @other_user

    post generate_pairings_restaurant_menu_path(@restaurant, @menu), as: :json

    assert_response :forbidden
  end
end
