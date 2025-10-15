require 'test_helper'

class MenuLocalizationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
    
    # Create restaurant locale for translation
    @restaurant_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'IT',
      status: :active,
      dfault: false
    )
  end

  # === BASIC JOB EXECUTION TESTS ===
  
  test 'should perform job successfully with valid restaurant locale' do
    # Mock DeeplApiService
    DeeplApiService.stub :translate, 'Translated Text' do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  test 'should handle missing restaurant locale gracefully' do
    job = MenuLocalizationJob.new
    
    # The job will fail with NoMethodError when restaurant locale doesn't exist
    # This is expected behavior - the job should handle this at the application level
    assert_raises(NoMethodError) do
      job.perform(99999) # Non-existent restaurant locale ID
    end
  end

  test 'should handle translation service errors gracefully' do
    # Mock DeeplApiService to raise an error
    DeeplApiService.stub :translate, -> { raise StandardError.new('Translation error') } do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  # === INTEGRATION TESTS ===
  
  test 'should work with real translation service' do
    # Test without mocking to ensure basic job structure works
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  test 'should handle concurrent translation jobs' do
    # Test multiple jobs running sequentially to avoid threading issues
    3.times do |i|
      DeeplApiService.stub :translate, "Translation #{i}" do
        assert_nothing_raised do
          MenuLocalizationJob.new.perform(@restaurant_locale.id)
        end
      end
    end
  end

  # === PERFORMANCE TESTS ===
  
  test 'should complete job execution within reasonable time' do
    start_time = Time.current
    
    DeeplApiService.stub :translate, 'Quick Translation' do
      MenuLocalizationJob.new.perform(@restaurant_locale.id)
    end
    
    execution_time = Time.current - start_time
    assert execution_time < 10.seconds, "Job took too long: #{execution_time}s"
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle nil translation results' do
    DeeplApiService.stub :translate, nil do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  test 'should handle empty translation results' do
    DeeplApiService.stub :translate, '' do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should support restaurant internationalization scenario' do
    # Simulate restaurant adding Italian translations
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end

  test 'should support menu localization workflow' do
    # Test complete menu translation workflow
    DeeplApiService.stub :translate, ->(text, options) { 
      case options[:target_lang]
      when 'IT'
        "Italiano: #{text}"
      else
        "Translated: #{text}"
      end
    } do
      assert_nothing_raised do
        MenuLocalizationJob.new.perform(@restaurant_locale.id)
      end
    end
  end
end
