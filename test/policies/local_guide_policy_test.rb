# frozen_string_literal: true

require 'test_helper'

class LocalGuidePolicyTest < ActiveSupport::TestCase
  setup do
    @guide = LocalGuide.create!(
      title: 'Test Guide',
      city: 'Dublin',
      country: 'Ireland',
      content: '<p>Test content</p>',
    )
    @admin = users(:one)
    @regular = users(:two)
  end

  test 'admin can index guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.index?
    end
  end

  test 'regular user cannot index guides' do
    @regular.stub(:admin?, false) do
      policy = LocalGuidePolicy.new(@regular, @guide)
      assert_not policy.index?
    end
  end

  test 'admin can show guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.show?
    end
  end

  test 'admin can create guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.create?
    end
  end

  test 'admin can update guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.update?
    end
  end

  test 'only super_admin can approve guides' do
    @admin.stub(:admin?, true) do
      @admin.stub(:super_admin?, false) do
        policy = LocalGuidePolicy.new(@admin, @guide)
        assert_not policy.approve?
      end
    end
  end

  test 'super_admin can approve guides' do
    @admin.stub(:super_admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.approve?
    end
  end

  test 'admin can archive guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.archive?
    end
  end

  test 'admin can regenerate guides' do
    @admin.stub(:admin?, true) do
      policy = LocalGuidePolicy.new(@admin, @guide)
      assert policy.regenerate?
    end
  end

  test 'scope returns all guides for admin' do
    @admin.stub(:admin?, true) do
      scope = LocalGuidePolicy::Scope.new(@admin, LocalGuide).resolve
      assert_includes scope, @guide
    end
  end

  test 'scope returns none for non-admin' do
    @regular.stub(:admin?, false) do
      scope = LocalGuidePolicy::Scope.new(@regular, LocalGuide).resolve
      assert_empty scope
    end
  end
end
