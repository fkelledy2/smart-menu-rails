require 'test_helper'

class HeroImagePolicyTest < ActiveSupport::TestCase
  def setup
    @admin_user = users(:admin)
    @regular_user = users(:one)
    @hero_image = HeroImage.create!(
      image_url: "https://example.com/test.jpg",
      alt_text: "Test image",
      status: :unapproved
    )
  end

  # Index tests
  test "admin can view index" do
    assert HeroImagePolicy.new(@admin_user, HeroImage).index?
  end

  test "regular user cannot view index" do
    assert_not HeroImagePolicy.new(@regular_user, HeroImage).index?
  end

  test "guest cannot view index" do
    assert_not HeroImagePolicy.new(nil, HeroImage).index?
  end

  # Show tests
  test "admin can view hero image" do
    assert HeroImagePolicy.new(@admin_user, @hero_image).show?
  end

  test "regular user cannot view hero image" do
    assert_not HeroImagePolicy.new(@regular_user, @hero_image).show?
  end

  test "guest cannot view hero image" do
    assert_not HeroImagePolicy.new(nil, @hero_image).show?
  end

  # Create tests
  test "admin can create hero image" do
    assert HeroImagePolicy.new(@admin_user, HeroImage.new).create?
  end

  test "regular user cannot create hero image" do
    assert_not HeroImagePolicy.new(@regular_user, HeroImage.new).create?
  end

  test "guest cannot create hero image" do
    assert_not HeroImagePolicy.new(nil, HeroImage.new).create?
  end

  # Update tests
  test "admin can update hero image" do
    assert HeroImagePolicy.new(@admin_user, @hero_image).update?
  end

  test "regular user cannot update hero image" do
    assert_not HeroImagePolicy.new(@regular_user, @hero_image).update?
  end

  test "guest cannot update hero image" do
    assert_not HeroImagePolicy.new(nil, @hero_image).update?
  end

  # Destroy tests
  test "admin can destroy hero image" do
    assert HeroImagePolicy.new(@admin_user, @hero_image).destroy?
  end

  test "regular user cannot destroy hero image" do
    assert_not HeroImagePolicy.new(@regular_user, @hero_image).destroy?
  end

  test "guest cannot destroy hero image" do
    assert_not HeroImagePolicy.new(nil, @hero_image).destroy?
  end

  # Scope tests
  test "admin scope returns all hero images" do
    HeroImage.create!(image_url: "https://example.com/1.jpg", status: :approved)
    HeroImage.create!(image_url: "https://example.com/2.jpg", status: :unapproved)

    scope = HeroImagePolicy::Scope.new(@admin_user, HeroImage).resolve
    assert_equal HeroImage.count, scope.count
  end

  test "regular user scope returns no hero images" do
    HeroImage.create!(image_url: "https://example.com/1.jpg", status: :approved)
    HeroImage.create!(image_url: "https://example.com/2.jpg", status: :unapproved)

    scope = HeroImagePolicy::Scope.new(@regular_user, HeroImage).resolve
    assert_equal 0, scope.count
  end

  test "guest scope returns no hero images" do
    HeroImage.create!(image_url: "https://example.com/1.jpg", status: :approved)

    scope = HeroImagePolicy::Scope.new(nil, HeroImage).resolve
    assert_equal 0, scope.count
  end
end
