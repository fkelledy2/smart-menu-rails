# frozen_string_literal: true

require 'test_helper'

class HerokuAppInventorySnapshotTest < ActiveSupport::TestCase
  def valid_attrs
    {
      captured_at: Time.current,
      space_name: 'smart-menu',
      app_id: 'app-001',
      app_name: 'smart-menu-web-production',
      environment: 'production',
      formation_json: [],
      addons_json: [],
    }
  end

  test 'valid with required attributes' do
    snap = HerokuAppInventorySnapshot.new(valid_attrs)
    assert snap.valid?
  end

  test 'requires captured_at' do
    snap = HerokuAppInventorySnapshot.new(valid_attrs.except(:captured_at))
    assert_not snap.valid?
  end

  test 'requires app_id' do
    snap = HerokuAppInventorySnapshot.new(valid_attrs.except(:app_id))
    assert_not snap.valid?
  end

  test 'requires valid environment' do
    snap = HerokuAppInventorySnapshot.new(valid_attrs.merge(environment: 'invalid'))
    assert_not snap.valid?
  end

  test 'accepts all valid environments' do
    HerokuAppInventorySnapshot::ENVIRONMENTS.each do |env|
      snap = HerokuAppInventorySnapshot.new(valid_attrs.merge(environment: env, app_id: "id-#{env}"))
      assert snap.valid?, "Expected #{env} to be valid"
    end
  end

  test 'production? returns true for production environment' do
    snap = HerokuAppInventorySnapshot.new(environment: 'production')
    assert snap.production?
  end

  test 'ephemeral? returns true for ephemeral environment' do
    snap = HerokuAppInventorySnapshot.new(environment: 'ephemeral')
    assert snap.ephemeral?
  end

  test 'for_space scope filters by space_name' do
    snaps = HerokuAppInventorySnapshot.for_space('smart-menu')
    snaps.each { |s| assert_equal 'smart-menu', s.space_name }
  end

  test 'for_environment scope filters by environment' do
    snaps = HerokuAppInventorySnapshot.for_environment('production')
    snaps.each { |s| assert_equal 'production', s.environment }
  end
end
