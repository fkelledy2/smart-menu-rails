require 'test_helper'

class HeroImageTest < ActiveSupport::TestCase
  def setup
    @hero_image = HeroImage.new(
      image_url: 'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg',
      alt_text: 'Busy restaurant interior',
      sequence: 1,
      status: :unapproved,
    )
  end

  test 'should be valid with valid attributes' do
    assert @hero_image.valid?
  end

  test 'should require image_url' do
    @hero_image.image_url = nil
    assert_not @hero_image.valid?
    assert_includes @hero_image.errors[:image_url], "can't be blank"
  end

  test 'should require valid URL format' do
    @hero_image.image_url = 'not-a-url'
    assert_not @hero_image.valid?
    assert_includes @hero_image.errors[:image_url], 'must be a valid URL'
  end

  test 'should accept http URLs' do
    @hero_image.image_url = 'http://example.com/image.jpg'
    assert @hero_image.valid?
  end

  test 'should accept https URLs' do
    @hero_image.image_url = 'https://example.com/image.jpg'
    assert @hero_image.valid?
  end

  test 'should require status' do
    @hero_image.status = nil
    assert_not @hero_image.valid?
    assert_includes @hero_image.errors[:status], "can't be blank"
  end

  test 'should have default status of unapproved' do
    hero_image = HeroImage.new(image_url: 'https://example.com/image.jpg')
    assert_equal 'unapproved', hero_image.status
  end

  test 'should have default sequence of 0' do
    hero_image = HeroImage.new(image_url: 'https://example.com/image.jpg')
    assert_equal 0, hero_image.sequence
  end

  test 'sequence should be an integer' do
    @hero_image.sequence = 'not-a-number'
    assert_not @hero_image.valid?
    assert_includes @hero_image.errors[:sequence], 'is not a number'
  end

  test 'sequence should be greater than or equal to 0' do
    @hero_image.sequence = -1
    assert_not @hero_image.valid?
    assert_includes @hero_image.errors[:sequence], 'must be greater than or equal to 0'
  end

  test 'should have approved and unapproved statuses' do
    assert_includes HeroImage.statuses.keys, 'approved'
    assert_includes HeroImage.statuses.keys, 'unapproved'
  end

  test 'approved? should return true for approved status' do
    @hero_image.status = :approved
    assert @hero_image.approved?
  end

  test 'approved? should return false for unapproved status' do
    @hero_image.status = :unapproved
    assert_not @hero_image.approved?
  end

  test 'approved scope should return only approved images' do
    approved = HeroImage.create!(
      image_url: 'https://example.com/approved.jpg',
      status: :approved,
    )
    unapproved = HeroImage.create!(
      image_url: 'https://example.com/unapproved.jpg',
      status: :unapproved,
    )

    approved_images = HeroImage.approved
    assert_includes approved_images, approved
    assert_not_includes approved_images, unapproved
  end

  test 'ordered scope should order by sequence then created_at' do
    image1 = HeroImage.create!(
      image_url: 'https://example.com/1.jpg',
      sequence: 2,
    )
    image2 = HeroImage.create!(
      image_url: 'https://example.com/2.jpg',
      sequence: 1,
    )
    image3 = HeroImage.create!(
      image_url: 'https://example.com/3.jpg',
      sequence: 1,
    )

    ordered_images = HeroImage.ordered.to_a
    assert_equal image2.id, ordered_images[0].id
    assert_equal image3.id, ordered_images[1].id
    assert_equal image1.id, ordered_images[2].id
  end

  test 'approved_for_carousel should return approved images in order' do
    approved1 = HeroImage.create!(
      image_url: 'https://example.com/approved1.jpg',
      status: :approved,
      sequence: 2,
    )
    approved2 = HeroImage.create!(
      image_url: 'https://example.com/approved2.jpg',
      status: :approved,
      sequence: 1,
    )
    unapproved = HeroImage.create!(
      image_url: 'https://example.com/unapproved.jpg',
      status: :unapproved,
      sequence: 0,
    )

    carousel_images = HeroImage.approved_for_carousel.to_a
    assert_equal 2, carousel_images.length
    assert_equal approved2.id, carousel_images[0].id
    assert_equal approved1.id, carousel_images[1].id
    assert_not_includes carousel_images, unapproved
  end

  test 'alt_text is optional' do
    @hero_image.alt_text = nil
    assert @hero_image.valid?
  end

  test 'source_url is optional' do
    @hero_image.source_url = nil
    assert @hero_image.valid?
  end
end
