require 'test_helper'

class FeatureTest < ActiveSupport::TestCase
  def setup
    @feature = features(:one)
  end

  test 'should be valid with key and descriptionKey' do
    feature = Feature.new(key: 'test_feature', descriptionKey: 'Test Feature Description')
    assert feature.valid?
  end

  test 'should require key' do
    feature = Feature.new(descriptionKey: 'Test Description')
    assert_not feature.valid?
    assert_includes feature.errors[:key], "can't be blank"
  end

  test 'should require descriptionKey' do
    feature = Feature.new(key: 'test_feature')
    assert_not feature.valid?
    assert_includes feature.errors[:descriptionKey], "can't be blank"
  end

  test 'should require unique key' do
    Feature.create!(key: 'unique_feature', descriptionKey: 'First Feature')
    feature2 = Feature.new(key: 'unique_feature', descriptionKey: 'Second Feature')

    assert_not feature2.valid?
    assert_includes feature2.errors[:key], 'has already been taken'
  end

  test 'should save valid feature' do
    feature = Feature.new(key: 'new_feature', descriptionKey: 'New Feature Description')
    assert feature.save
    assert_not_nil feature.id
  end

  test 'should have many features_plans' do
    assert_respond_to @feature, :features_plans
    assert_respond_to @feature, :plans
  end

  test 'should have IdentityCache configuration' do
    assert Feature.respond_to?(:fetch)
    assert Feature.respond_to?(:fetch_by_key)
  end

  test 'should cache by key' do
    # Test that the cache_index :key configuration works
    feature = Feature.create!(key: 'cacheable_feature', descriptionKey: 'Cacheable Feature')

    # This tests that the cache index is configured
    cached_feature = Feature.fetch_by_key('cacheable_feature')
    # Handle case where fetch_by_key returns an array
    cached_feature = cached_feature.first if cached_feature.is_a?(Array)
    assert_equal feature.id, cached_feature.id
  end

  test 'should handle status field' do
    feature = Feature.new(key: 'status_feature', descriptionKey: 'Status Feature', status: 1)
    assert feature.valid?
    assert feature.save
  end

  test 'should associate with plans through features_plans' do
    plan = plans(:one)
    feature = Feature.create!(key: 'test_association_feature', descriptionKey: 'Test Association Feature')

    # Create association
    FeaturesPlan.create!(feature: feature, plan: plan)

    assert_includes feature.plans, plan
    assert_includes plan.features, feature
  end

  test 'should destroy associated features_plans when destroyed' do
    feature = Feature.create!(key: 'destroyable_feature', descriptionKey: 'Destroyable Feature')
    plan = plans(:one)
    FeaturesPlan.create!(feature: feature, plan: plan)

    assert_difference('FeaturesPlan.count', -1) do
      feature.destroy
    end
  end

  test 'should handle key validation edge cases' do
    # Test empty string
    feature = Feature.new(key: '', descriptionKey: 'Test')
    assert_not feature.valid?

    # Test nil key
    feature = Feature.new(key: nil, descriptionKey: 'Test')
    assert_not feature.valid?
  end

  test 'should store attributes correctly' do
    key = 'stored_feature'
    description = 'Stored Feature Description'
    status = 1

    feature = Feature.create!(key: key, descriptionKey: description, status: status)

    assert_equal key, feature.key
    assert_equal description, feature.descriptionKey
    assert_equal status, feature.status
  end
end
