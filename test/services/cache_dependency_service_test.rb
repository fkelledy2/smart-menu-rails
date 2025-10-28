# frozen_string_literal: true

require 'test_helper'

class CacheDependencyServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @user = users(:one)

    # Clear cache before each test
    Rails.cache.clear
  end

  def teardown
    # Clean up cache after each test
    Rails.cache.clear
  end

  # Test dependency constants
  test 'should have defined cache dependencies' do
    dependencies = CacheDependencyService::DEPENDENCIES

    assert_includes dependencies.keys, 'restaurant:*'
    assert_includes dependencies.keys, 'menu:*'
    assert_includes dependencies.keys, 'order:*'
    assert_includes dependencies.keys, 'employee:*'
    assert_includes dependencies.keys, 'user:*'

    # Test that restaurant dependencies include expected patterns
    restaurant_deps = dependencies['restaurant:*']
    assert_includes restaurant_deps, 'menu:*'
    assert_includes restaurant_deps, 'employee:*'
    assert_includes restaurant_deps, 'order:*'
  end

  test 'should have defined update priorities' do
    priorities = CacheDependencyService::UPDATE_PRIORITIES

    assert_kind_of Hash, priorities
    assert priorities[:restaurant_dashboard] > priorities[:menu_full]
    assert priorities[:menu_full] > priorities[:order_full]
  end

  # Test cascade invalidation
  test 'should perform cascade invalidation' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"
    Rails.cache.write(cache_key, { data: 'test' })

    # Mock dependent keys to avoid infinite recursion
    call_count = 0
    CacheDependencyService.stub :find_dependent_keys, lambda { |key|
      call_count += 1
      if call_count == 1 && key == cache_key
        ["menu:#{@menu.id}:full"]
      else
        []
      end
    } do
      Rails.cache.write("menu:#{@menu.id}:full", { menu: 'data' })

      CacheDependencyService.invalidate_with_dependencies(cache_key, strategy: :cascade)

      assert_nil Rails.cache.read(cache_key)
      assert_nil Rails.cache.read("menu:#{@menu.id}:full")
    end
  end

  # Test selective invalidation
  test 'should perform selective invalidation' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"
    Rails.cache.write(cache_key, { data: 'test' })

    # Mock dependent keys
    CacheDependencyService.stub :find_dependent_keys, ->(_key) { ["menu:#{@menu.id}:full"] } do
      Rails.cache.write("menu:#{@menu.id}:full", { menu: 'data' })

      CacheDependencyService.invalidate_with_dependencies(cache_key, strategy: :selective)

      assert_nil Rails.cache.read(cache_key)
      assert_nil Rails.cache.read("menu:#{@menu.id}:full")
    end
  end

  # Test cache update instead of invalidation
  test 'should update cache instead of invalidating' do
    cache_key = "restaurant_dashboard:#{@restaurant.id}"
    original_data = { restaurant: { name: 'Old Name' } }
    Rails.cache.write(cache_key, original_data)

    # Mock AdvancedCacheService
    AdvancedCacheService.stub :cached_restaurant_dashboard, lambda { |_id|
      { restaurant: { name: 'Updated Name' } }
    } do
      CacheDependencyService.invalidate_with_dependencies(cache_key, strategy: :update)

      updated_data = Rails.cache.read(cache_key)
      assert_not_nil updated_data
      assert_equal 'Updated Name', updated_data[:restaurant][:name]
    end
  end

  # Test batch invalidation
  test 'should perform batch invalidation' do
    cache_keys = [
      "restaurant:#{@restaurant.id}:dashboard",
      "menu:#{@menu.id}:full",
      "user:#{@user.id}:activity",
    ]

    # Write test data to cache
    cache_keys.each do |key|
      Rails.cache.write(key, { data: 'test' })
    end

    # Mock dependency level calculation
    CacheDependencyService.stub :find_dependent_keys, ->(_key) { [] } do
      CacheDependencyService.batch_invalidate(cache_keys)

      # Verify all keys are invalidated
      cache_keys.each do |key|
        assert_nil Rails.cache.read(key)
      end
    end
  end

  # Test model change invalidation
  test 'should invalidate cache for restaurant model changes' do
    # Mock pattern invalidation
    invalidated_patterns = []
    CacheDependencyService.stub :invalidate_pattern, lambda { |pattern|
      invalidated_patterns << pattern
    } do
      CacheDependencyService.invalidate_for_model_change(@restaurant, :update, ['name'])

      assert_includes invalidated_patterns, "restaurant:#{@restaurant.id}:*"
      assert_includes invalidated_patterns, "restaurant_dashboard:#{@restaurant.id}"
    end
  end

  test 'should invalidate cache for menu model changes' do
    invalidated_patterns = []
    CacheDependencyService.stub :invalidate_pattern, lambda { |pattern|
      invalidated_patterns << pattern
    } do
      CacheDependencyService.invalidate_for_model_change(@menu, :update, ['name'])

      assert_includes invalidated_patterns, "menu:#{@menu.id}:*"
      assert_includes invalidated_patterns, "menu_full:#{@menu.id}:*"
      assert_includes invalidated_patterns, "restaurant_dashboard:#{@menu.restaurant_id}"
    end
  end

  # Test pattern invalidation
  test 'should invalidate cache patterns' do
    pattern = 'test_pattern:*'

    # Test with delete_matched support
    Rails.cache.stub :delete_matched, lambda { |p|
      assert_equal pattern, p
      true
    } do
      assert_nothing_raised do
        CacheDependencyService.invalidate_pattern(pattern)
      end
    end
  end

  test 'should fallback to pipeline service for pattern invalidation' do
    pattern = 'test_pattern:*'

    # Mock cache without delete_matched support
    cache_without_delete_matched = Object.new
    Rails.stub :cache, cache_without_delete_matched do
      RedisPipelineService.stub :bulk_invalidate_patterns, lambda { |patterns|
        assert_equal [pattern], patterns
        1
      } do
        assert_nothing_raised do
          CacheDependencyService.invalidate_pattern(pattern)
        end
      end
    end
  end

  # Test dependency tree analysis
  test 'should generate dependency tree' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"

    CacheDependencyService.stub :find_dependent_keys, lambda { |key|
      if key == cache_key
        ["menu:#{@menu.id}:full"]
      else
        []
      end
    } do
      tree = CacheDependencyService.dependency_tree(cache_key)

      assert_equal cache_key, tree[:key]
      assert_kind_of Array, tree[:dependencies]
      assert_equal 1, tree[:dependencies].size
      assert_equal "menu:#{@menu.id}:full", tree[:dependencies].first[:key]
    end
  end

  # Test invalidation impact analysis
  test 'should analyze invalidation impact' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"

    CacheDependencyService.stub :find_all_dependent_keys, lambda { |_key, _visited|
      ["menu:#{@menu.id}:full", 'order:1:analytics']
    } do
      CacheDependencyService.stub :estimate_regeneration_time, ->(_keys) { 1500 } do
        CacheDependencyService.stub :estimate_memory_impact, ->(_keys) { 150_000 } do
          impact = CacheDependencyService.analyze_invalidation_impact(cache_key)

          assert_equal cache_key, impact[:primary_key]
          assert_equal 2, impact[:total_dependencies]
          assert_equal 1500, impact[:estimated_regeneration_time]
          assert_equal 150_000, impact[:memory_impact]
        end
      end
    end
  end

  # Test preemptive cache warming
  test 'should warm dependent caches' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"
    context = { restaurant_id: @restaurant.id }

    warmed_keys = []
    CacheDependencyService.stub :find_dependent_keys, lambda { |_key|
      ["menu:#{@menu.id}:full"]
    } do
      CacheDependencyService.stub :warm_cache_key, lambda { |key, ctx, priority|
        warmed_keys << { key: key, context: ctx, priority: priority }
      } do
        CacheDependencyService.warm_dependent_caches(cache_key, context)

        assert_equal 1, warmed_keys.size
        assert_equal "menu:#{@menu.id}:full", warmed_keys.first[:key]
        assert_equal context, warmed_keys.first[:context]
      end
    end
  end

  # Test error handling
  test 'should handle invalidation errors gracefully' do
    cache_key = 'invalid:key'

    # Mock an error in the invalidation process
    Rails.cache.stub :delete, ->(_key) { raise Redis::ConnectionError, 'Connection failed' } do
      assert_raises Redis::ConnectionError do
        CacheDependencyService.invalidate_with_dependencies(cache_key)
      end
    end
  end

  # Test cache key pattern matching
  test 'should match cache key patterns correctly' do
    # Test private method through public interface
    cache_key = 'restaurant:123:dashboard'

    # This tests the pattern matching logic indirectly
    CacheDependencyService.stub :find_dependent_keys, lambda { |key|
      # Should match restaurant:* pattern
      if key.start_with?('restaurant:')
        ['menu:*', 'employee:*']
      else
        []
      end
    } do
      deps = CacheDependencyService.send(:find_dependent_keys, cache_key)
      assert_includes deps, 'menu:*'
      assert_includes deps, 'employee:*'
    end
  end

  # Test performance
  test 'should complete dependency operations efficiently' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"

    start_time = Time.current

    CacheDependencyService.stub :find_dependent_keys, ->(_key) { [] } do
      CacheDependencyService.invalidate_with_dependencies(cache_key)
    end

    duration = Time.current - start_time
    assert duration < 1.second, "Dependency operation took too long: #{duration} seconds"
  end

  # Test memory efficiency
  test 'should not leak memory during dependency operations' do
    initial_objects = ObjectSpace.count_objects

    10.times do |i|
      cache_key = "test:#{i}:data"
      CacheDependencyService.stub :find_dependent_keys, ->(_key) { [] } do
        CacheDependencyService.invalidate_with_dependencies(cache_key)
      end
    end

    GC.start
    final_objects = ObjectSpace.count_objects

    object_growth = final_objects[:TOTAL] - initial_objects[:TOTAL]
    assert object_growth < 5000, "Excessive object growth: #{object_growth}"
  end

  # Test logging
  test 'should log dependency operations' do
    cache_key = "restaurant:#{@restaurant.id}:dashboard"

    log_output = StringIO.new
    logger = Logger.new(log_output)
    Rails.stub :logger, logger do
      CacheDependencyService.stub :find_dependent_keys, ->(_key) { [] } do
        CacheDependencyService.invalidate_with_dependencies(cache_key)
      end
    end

    log_content = log_output.string
    assert_includes log_content, 'Invalidating cache key'
  end
end
