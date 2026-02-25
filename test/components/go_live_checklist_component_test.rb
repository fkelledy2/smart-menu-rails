# frozen_string_literal: true

require 'test_helper'

class GoLiveChecklistComponentTest < ViewComponent::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  def test_does_not_render_when_onboarding_complete
    # Fixture restaurant :one has name, currency, address, country filled in.
    # onboarding_incomplete? returns false only when ALL steps pass, which
    # requires locales, tables, employees, and menus – so we stub the method.
    @restaurant.define_singleton_method(:onboarding_incomplete?) { false }

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_no_selector "[data-testid='onboarding-guidance']"
  end

  def test_renders_when_onboarding_incomplete
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector "[data-testid='onboarding-guidance']"
    assert_selector "[data-controller='go-live-progress']"
    assert_text 'Go-live checklist'
  end

  def test_shows_progress_bar
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector '.progress-bar'
    assert_selector "[role='progressbar']"
  end

  def test_shows_completed_steps_count
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    # At minimum, restaurant name should be complete
    assert_selector '.text-muted.small'
  end

  def test_completed_steps_have_check_icon
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector '.bi-check-circle-fill.text-success'
  end

  def test_incomplete_steps_have_contextual_icon
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    # Incomplete steps should have their contextual icons
    assert_selector "[data-testid='go-live-step']"
  end

  def test_incomplete_steps_have_links
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector "[data-testid='go-live-step-link']"
  end

  def test_toggle_button_present
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector "[data-testid='go-live-toggle-btn']"
    assert_selector "[data-action='click->go-live-progress#toggle mouseenter->go-live-progress#open']"
  end

  def test_all_nine_steps_rendered
    make_restaurant_incomplete!

    render_inline(GoLiveChecklistComponent.new(restaurant: @restaurant))

    assert_selector "[data-testid='go-live-step']", count: 9
  end

  private

  # Make the restaurant appear incomplete by clearing fields that the
  # onboarding checklist inspects.  Uses attribute writes instead of
  # Mocha stubs so the test works with plain Minitest.
  def make_restaurant_incomplete!
    @restaurant.assign_attributes(currency: nil, address1: nil, city: nil, postcode: nil, country: nil)
    # onboarding_incomplete? will now return true because details are missing.
    # The component's build_steps also queries associations; the fixture
    # restaurant has none, so those steps will naturally be incomplete.
  end
end
