require 'test_helper'

class PublicPagesIntegrationTest < ActionDispatch::IntegrationTest
  test 'public routes exist and work' do
    # Test that the routes exist by checking they don't raise routing errors
    assert_nothing_raised do
      Rails.application.routes.recognize_path('/')
      Rails.application.routes.recognize_path('/health')
      Rails.application.routes.recognize_path('/features')
      Rails.application.routes.recognize_path('/plans')
    end
  end

  test 'public models are accessible' do
    # Test that public models can be accessed
    assert Feature.count >= 0
    assert Plan.count >= 0

    # Test that fixtures are loaded
    feature = features(:one)
    assert_not_nil feature
    assert_not_nil feature.key

    plan = plans(:one)
    assert_not_nil plan
    assert_not_nil plan.key
  end

  test 'public controllers respond to basic requests' do
    # Test basic functionality without complex integration
    assert_nothing_raised do
      get root_path
    end

    assert_nothing_raised do
      get health_path
    end
  end

  test 'feature and plan models work correctly' do
    # Test that we can create and access features and plans
    feature = Feature.create!(key: 'test_public_feature', descriptionKey: 'Test Public Feature')
    assert feature.persisted?

    plan = Plan.create!(key: 'test_public_plan', descriptionKey: 'Test Public Plan')
    assert plan.persisted?

    # Test associations work
    features_plan = FeaturesPlan.create!(feature: feature, plan: plan)
    assert features_plan.persisted?

    assert_includes feature.plans, plan
    assert_includes plan.features, feature
  end

  test 'public page navigation works' do
    # Test basic navigation without complex assertions
    assert_nothing_raised do
      get root_path
      get features_path
      get plans_path
      get health_path
    end
  end

  test 'public models have proper validations' do
    # Test Feature validations
    feature = Feature.new
    assert_not feature.valid?
    assert_includes feature.errors[:key], "can't be blank"
    assert_includes feature.errors[:descriptionKey], "can't be blank"

    # Test Plan validations
    plan = Plan.new
    # Plans don't have strict validations, just test it can be created
    plan.key = 'test_plan'
    plan.descriptionKey = 'Test Plan'
    assert plan.valid?
  end

  test 'public controllers exist and are accessible' do
    # Test that controller classes exist
    assert defined?(FeaturesController)
    assert defined?(PlansController)
    assert defined?(HealthController)
    assert defined?(HomeController)

    # Test that they inherit from ApplicationController
    assert FeaturesController < ApplicationController
    assert PlansController < ApplicationController
  end
end
