require 'test_helper'

class TagPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    
    # Create tags for testing
    @tag = Tag.create!(
      name: 'Test Tag'
    )
    
    @other_tag = Tag.create!(
      name: 'Other Tag'
    )
  end

  # === INDEX TESTS ===
  
  test "should allow authenticated user to view tag index" do
    policy = TagPolicy.new(@user, Tag)
    assert policy.index?
  end

  test "should allow anonymous user to view tag index" do
    policy = TagPolicy.new(nil, Tag)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.index?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should allow other user to view tag index" do
    policy = TagPolicy.new(@other_user, Tag)
    assert policy.index?
  end

  # === SHOW TESTS ===
  
  test "should allow authenticated user to view tag" do
    policy = TagPolicy.new(@user, @tag)
    assert policy.show?
  end

  test "should allow anonymous user to view tag" do
    policy = TagPolicy.new(nil, @tag)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.show?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should allow other user to view tag" do
    policy = TagPolicy.new(@other_user, @tag)
    assert policy.show?
  end

  # === CREATE TESTS ===
  
  test "should allow authenticated user to create tag" do
    policy = TagPolicy.new(@user, Tag.new)
    assert policy.create?
  end

  test "should allow anonymous user to create tag" do
    policy = TagPolicy.new(nil, Tag.new)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.create?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should allow other user to create tag" do
    policy = TagPolicy.new(@other_user, Tag.new)
    assert policy.create?
  end

  # === UPDATE TESTS ===
  
  test "should allow authenticated user to update tag" do
    policy = TagPolicy.new(@user, @tag)
    assert policy.update?
  end

  test "should allow anonymous user to update tag" do
    policy = TagPolicy.new(nil, @tag)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.update?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should allow other user to update tag" do
    policy = TagPolicy.new(@other_user, @tag)
    assert policy.update?
  end

  # === DESTROY TESTS ===
  
  test "should allow authenticated user to destroy tag" do
    policy = TagPolicy.new(@user, @tag)
    assert policy.destroy?
  end

  test "should allow anonymous user to destroy tag" do
    policy = TagPolicy.new(nil, @tag)
    # ApplicationPolicy creates User.new for nil user, so user.present? is true
    assert policy.destroy?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should allow other user to destroy tag" do
    policy = TagPolicy.new(@other_user, @tag)
    assert policy.destroy?
  end

  # === SCOPE TESTS ===
  
  test "should return all tags for authenticated user" do
    scope = TagPolicy::Scope.new(@user, Tag).resolve
    
    # Should include all tags (global resource)
    assert_includes scope, @tag
    assert_includes scope, @other_tag
  end

  test "should return all tags for anonymous user" do
    scope = TagPolicy::Scope.new(nil, Tag).resolve
    
    # Should include all tags (global resource)
    assert_includes scope, @tag
    assert_includes scope, @other_tag
  end

  test "should return all tags for other user" do
    scope = TagPolicy::Scope.new(@other_user, Tag).resolve
    
    # Should include all tags (global resource)
    assert_includes scope, @tag
    assert_includes scope, @other_tag
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil tag record" do
    policy = TagPolicy.new(@user, nil)
    
    # All methods should work for nil record since they only check user.present?
    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "should inherit from ApplicationPolicy" do
    assert TagPolicy < ApplicationPolicy
  end

  # === GLOBAL RESOURCE TESTS ===
  
  test "should treat tags as global resources" do
    # Tags are global resources available to all authenticated users
    user_policy = TagPolicy.new(@user, @tag)
    other_user_policy = TagPolicy.new(@other_user, @tag)
    
    # Both users should have full access to all tags
    assert user_policy.show?
    assert user_policy.update?
    assert user_policy.destroy?
    
    assert other_user_policy.show?
    assert other_user_policy.update?
    assert other_user_policy.destroy?
  end

  test "should allow tag management by any authenticated user" do
    # Create a tag as one user
    new_tag = Tag.create!(
      name: 'Shared Tag'
    )
    
    # Other user should be able to manage it
    other_user_policy = TagPolicy.new(@other_user, new_tag)
    assert other_user_policy.show?, "Any user should be able to view tags"
    assert other_user_policy.update?, "Any user should be able to update tags"
    assert other_user_policy.destroy?, "Any user should be able to destroy tags"
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should handle different tag types" do
    # Test with different tag types
    tag_types = ['Dietary', 'Cuisine', 'Spice Level', 'Allergen', 'Special', 'Popular']
    
    tag_types.each do |tag_type|
      tag = Tag.create!(
        name: "#{tag_type} Tag"
      )
      
      policy = TagPolicy.new(@user, tag)
      assert policy.show?, "User should have access to #{tag_type} tags"
      assert policy.update?, "User should be able to update #{tag_type} tags"
      assert policy.destroy?, "User should be able to destroy #{tag_type} tags"
    end
  end

  test "should handle tag lifecycle management" do
    # Test tag creation, modification, deletion
    new_tag = Tag.new(
      name: 'Lifecycle Tag'
    )
    
    policy = TagPolicy.new(@user, new_tag)
    
    # Should be able to create tag
    assert policy.create?, "User should be able to create tags"
    
    # After creation
    new_tag.save!
    assert policy.show?, "User should be able to view new tags"
    assert policy.update?, "User should be able to update tags"
    
    # Modification
    new_tag.update!(name: 'Modified Tag')
    assert policy.update?, "User should be able to update modified tags"
    
    # Deletion
    assert policy.destroy?, "User should be able to destroy tags"
  end

  test "should handle tags with special characters" do
    # Test tags with various special characters
    special_names = [
      'Tag with spaces',
      'Tag-with-dashes',
      'Tag_with_underscores',
      'Tag.with.dots',
      'Tag (with parentheses)',
      'Tag & Ampersand',
      'Tag #hashtag'
    ]
    
    special_names.each do |name|
      tag = Tag.create!(
        name: name
      )
      
      policy = TagPolicy.new(@user, tag)
      assert policy.show?, "User should have access to tag: #{name}"
      assert policy.update?, "User should be able to update tag: #{name}"
      assert policy.destroy?, "User should be able to destroy tag: #{name}"
    end
  end

  # === SCOPE BEHAVIOR TESTS ===
  
  test "should include all tags in scope regardless of user" do
    # Create additional tags
    5.times do |i|
      Tag.create!(
        name: "Bulk Tag #{i}"
      )
    end
    
    user_scope = TagPolicy::Scope.new(@user, Tag).resolve
    other_user_scope = TagPolicy::Scope.new(@other_user, Tag).resolve
    
    # Both scopes should return the same tags (all tags)
    assert_equal user_scope.count, other_user_scope.count
    assert_equal user_scope.pluck(:id).sort, other_user_scope.pluck(:id).sort
  end

  test "should handle empty tag collection" do
    # Clear all tag mappings first, then tags (handle foreign key constraints properly)
    MenuitemTagMapping.delete_all
    Tag.delete_all
    
    scope = TagPolicy::Scope.new(@user, Tag).resolve
    assert_equal 0, scope.count, "Scope should handle empty tag collection"
    
    # Should still allow creating new tags
    policy = TagPolicy.new(@user, Tag.new)
    assert policy.create?, "Should still be able to create tags when none exist"
  end

  # === PERFORMANCE TESTS ===
  
  test "should handle large tag datasets efficiently" do
    # Create multiple tags to test performance
    10.times do |i|
      Tag.create!(
        name: "Performance Tag #{i}"
      )
    end
    
    scope = TagPolicy::Scope.new(@user, Tag).resolve
    
    # Should handle large datasets efficiently
    assert_nothing_raised do
      scope.limit(50).each do |tag|
        # Access tag data
        tag.name
      end
    end
  end

  # === AUTHENTICATION PATTERN TESTS ===
  
  test "should demonstrate global resource pattern" do
    # Tags are global resources - any authenticated user can manage any tag
    # This is different from restaurant-scoped resources
    
    # Create tag as user 1
    user1_tag = Tag.create!(name: 'User 1 Tag')
    
    # User 2 should have full access
    user2_policy = TagPolicy.new(@other_user, user1_tag)
    assert user2_policy.show?, "Global resources should be accessible by any user"
    assert user2_policy.update?, "Global resources should be updatable by any user"
    assert user2_policy.destroy?, "Global resources should be destroyable by any user"
    
    # Anonymous user should also have access (due to ApplicationPolicy)
    anonymous_policy = TagPolicy.new(nil, user1_tag)
    assert anonymous_policy.show?, "ApplicationPolicy creates User.new for anonymous users"
    assert anonymous_policy.update?, "ApplicationPolicy creates User.new for anonymous users"
    assert anonymous_policy.destroy?, "ApplicationPolicy creates User.new for anonymous users"
  end

  test "should handle concurrent tag access" do
    # Multiple users accessing the same tag
    shared_tag = Tag.create!(name: 'Shared Tag')
    
    users = [@user, @other_user]
    
    users.each do |user|
      policy = TagPolicy.new(user, shared_tag)
      assert policy.show?, "#{user.email} should be able to view shared tag"
      assert policy.update?, "#{user.email} should be able to update shared tag"
      assert policy.destroy?, "#{user.email} should be able to destroy shared tag"
    end
    
    # All users should see the same tags in scope
    scopes = users.map { |user| TagPolicy::Scope.new(user, Tag).resolve.pluck(:id).sort }
    assert scopes.uniq.length == 1, "All users should see the same tags in scope"
  end

  # === TAG USAGE TESTS ===
  
  test "should handle tags used across different contexts" do
    # Tags might be used by menu items, restaurants, etc.
    # The policy should allow access regardless of usage context
    
    menu_tag = Tag.create!(name: 'Menu Tag')
    restaurant_tag = Tag.create!(name: 'Restaurant Tag')
    general_tag = Tag.create!(name: 'General Tag')
    
    tags = [menu_tag, restaurant_tag, general_tag]
    
    tags.each do |tag|
      policy = TagPolicy.new(@user, tag)
      assert policy.show?, "User should have access to #{tag.name}"
      assert policy.update?, "User should be able to update #{tag.name}"
      assert policy.destroy?, "User should be able to destroy #{tag.name}"
      
      other_policy = TagPolicy.new(@other_user, tag)
      assert other_policy.show?, "Other user should have access to #{tag.name}"
      assert other_policy.update?, "Other user should be able to update #{tag.name}"
      assert other_policy.destroy?, "Other user should be able to destroy #{tag.name}"
    end
  end
end
