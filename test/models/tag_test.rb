require 'test_helper'

class TagTest < ActiveSupport::TestCase
  def setup
    @tag = tags(:one)
  end

  # === VALIDATION TESTS ===
  
  test "should be valid with valid attributes" do
    assert @tag.valid?
  end

  test "should require name" do
    @tag.name = nil
    assert_not @tag.valid?
    assert_includes @tag.errors[:name], "can't be blank"
  end

  test "should accept blank description" do
    @tag.description = nil
    assert @tag.valid?
  end

  # === ASSOCIATION TESTS ===
  
  test "should have many menuitem_tag_mappings" do
    assert_respond_to @tag, :menuitem_tag_mappings
  end

  test "should have many menuitems through mappings" do
    assert_respond_to @tag, :menuitems
  end

  # === FACTORY/CREATION TESTS ===
  
  test "should create tag with valid data" do
    tag = Tag.new(
      name: "Vegetarian",
      description: "Suitable for vegetarians"
    )
    assert tag.save
    assert_equal "Vegetarian", tag.name
    assert_equal "Suitable for vegetarians", tag.description
  end

  test "should create tag with minimal data" do
    tag = Tag.new(name: "Spicy")
    assert tag.save
    assert_equal "Spicy", tag.name
  end

  # === DEPENDENT DESTROY TESTS ===
  
  test "should have correct dependent destroy configuration" do
    reflection = Tag.reflect_on_association(:menuitem_tag_mappings)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===
  
  test "should have identity cache configured" do
    assert Tag.respond_to?(:cache_index)
  end
end
