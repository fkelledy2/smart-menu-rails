require 'test_helper'

class TestimonialPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin)
    @owner = users(:one)
    @other_user = users(:two)
    @testimonial = testimonials(:one) # owned by user :one
    @other_testimonial = testimonials(:two) # owned by user :two
  end

  test 'index is allowed for admin' do
    policy = TestimonialPolicy.new(@admin, @testimonial)
    assert policy.index?
  end

  test 'index is denied for regular user' do
    policy = TestimonialPolicy.new(@owner, @testimonial)
    assert_not policy.index?
  end

  test 'show is allowed for authenticated user' do
    policy = TestimonialPolicy.new(@owner, @testimonial)
    assert policy.show?
  end

  test 'create is allowed for authenticated user' do
    policy = TestimonialPolicy.new(@owner, @testimonial)
    assert policy.create?
  end

  test 'update is allowed for owner' do
    policy = TestimonialPolicy.new(@owner, @testimonial)
    assert policy.update?
  end

  test 'update is denied for non-owner non-admin' do
    policy = TestimonialPolicy.new(@other_user, @testimonial)
    assert_not policy.update?
  end

  test 'update is allowed for admin on any testimonial' do
    policy = TestimonialPolicy.new(@admin, @testimonial)
    assert policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = TestimonialPolicy.new(@owner, @testimonial)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner non-admin' do
    policy = TestimonialPolicy.new(@other_user, @testimonial)
    assert_not policy.destroy?
  end

  test 'destroy is allowed for admin' do
    policy = TestimonialPolicy.new(@admin, @testimonial)
    assert policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert TestimonialPolicy < ApplicationPolicy
  end
end
