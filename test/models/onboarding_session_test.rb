require 'test_helper'

class OnboardingSessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @session = OnboardingSession.create!(
      user: @user,
      status: :started,
    )
  end

  # Association tests
  test 'belongs to user optionally' do
    assert_respond_to @session, :user
    session = OnboardingSession.new
    assert session.valid?
  end

  test 'belongs to restaurant optionally' do
    assert_respond_to @session, :restaurant
  end

  test 'belongs to menu optionally' do
    assert_respond_to @session, :menu
  end

  # Status enum tests (simplified: started → completed)
  test 'has status enum with started and completed' do
    assert_respond_to @session, :status
    assert_respond_to @session, :started?
    assert_respond_to @session, :completed?
  end

  test 'can transition from started to completed' do
    @session.update!(status: :started)
    assert @session.started?

    @session.update!(status: :completed)
    assert @session.completed?
  end

  # Wizard data accessor — only restaurant_name is still used
  test 'can set and get restaurant_name' do
    @session.restaurant_name = 'Test Restaurant'
    assert_equal 'Test Restaurant', @session.restaurant_name
  end

  # Progress calculation (simplified: 0% or 100%)
  test 'progress is 0 when started' do
    @session.status = :started
    assert_equal 0, @session.progress_percentage
  end

  test 'progress is 100 when completed' do
    @session.status = :completed
    assert_equal 100, @session.progress_percentage
  end

  # Persistence
  test 'persists wizard_data with restaurant_name' do
    @session.restaurant_name = 'Test Restaurant'
    @session.save!

    @session.reload
    assert_equal 'Test Restaurant', @session.restaurant_name
  end

  test 'wizard_data is serialized as JSON' do
    @session.restaurant_name = 'Test'
    @session.save!

    raw_data = @session.read_attribute(:wizard_data)
    assert_kind_of Hash, raw_data
  end
end
